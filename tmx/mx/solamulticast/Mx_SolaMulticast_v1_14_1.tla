--------------------- MODULE Mx_SolaMulticast_v1_14_1 ----------------------
(***************************************************************************)
(* TMX Group Sola Multicast v1.14.1                                        *)
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
(* Note: Strike Price Fraction Pair is chosen by Strike Price Fraction     *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Trade Price Fraction Pair is chosen by Trade Price Fraction       *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Net Change Fraction Pair is chosen by Net Change Fraction         *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Net Change Future Options Trade Message Fraction Pair is chosen   *)
(* by Net Change Fraction Indicator, which every arm reads at the same     *)
(* place among fields of the same widths, and every value of it reads one  *)
(* of them: each arm is the same bytes, read as those bytes, and what the  *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Net Change Futures Trade Message Fraction Pair is chosen by Net   *)
(* Change Fraction Indicator, which every arm reads at the same place      *)
(* among fields of the same widths, and every value of it reads one of     *)
(* them: each arm is the same bytes, read as those bytes, and what the     *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Strike Price Schedule Notice Fraction Pair is chosen by Strike    *)
(* Price Fraction Indicator, which every arm reads at the same place among *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Bid Price Quote is chosen by Bid Price Quote Opening, which every *)
(* arm reads at the same place among fields of the same widths, and every  *)
(* value of it reads one of them: each arm is the same bytes, read as      *)
(* those bytes, and what the choice names is how they are read.            *)
(*                                                                         *)
(* Note: Ask Price Quote is chosen by Ask Price Quote Opening, which every *)
(* arm reads at the same place among fields of the same widths, and every  *)
(* value of it reads one of them: each arm is the same bytes, read as      *)
(* those bytes, and what the choice names is how they are read.            *)
(*                                                                         *)
(* Note: Bid Price Quote Futures Quote Message is chosen by Bid Price      *)
(* Quote Opening, which every arm reads at the same place among fields of  *)
(* the same widths, and every value of it reads one of them: each arm is   *)
(* the same bytes, read as those bytes, and what the choice names is how   *)
(* they are read.                                                          *)
(*                                                                         *)
(* Note: Ask Price Quote Futures Quote Message is chosen by Ask Price      *)
(* Quote Opening, which every arm reads at the same place among fields of  *)
(* the same widths, and every value of it reads one of them: each arm is   *)
(* the same bytes, read as those bytes, and what the choice names is how   *)
(* they are read.                                                          *)
(*                                                                         *)
(* Note: Bid Price Quote Market Depth Level is chosen by Bid Price Quote   *)
(* Opening, which every arm reads at the same place among fields of the    *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Ask Price Quote Market Depth Level is chosen by Ask Price Quote   *)
(* Opening, which every arm reads at the same place among fields of the    *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Bid Price Quote Market Depth Level HB is chosen by Bid Price      *)
(* Quote Opening, which every arm reads at the same place among fields of  *)
(* the same widths, and every value of it reads one of them: each arm is   *)
(* the same bytes, read as those bytes, and what the choice names is how   *)
(* they are read.                                                          *)
(*                                                                         *)
(* Note: Ask Price Quote Market Depth Level HB is chosen by Ask Price      *)
(* Quote Opening, which every arm reads at the same place among fields of  *)
(* the same widths, and every value of it reads one of them: each arm is   *)
(* the same bytes, read as those bytes, and what the choice names is how   *)
(* they are read.                                                          *)
(*                                                                         *)
(* Note: Bid Price Quote Market Depth Level HF is chosen by Bid Price      *)
(* Quote Opening, which every arm reads at the same place among fields of  *)
(* the same widths, and every value of it reads one of them: each arm is   *)
(* the same bytes, read as those bytes, and what the choice names is how   *)
(* they are read.                                                          *)
(*                                                                         *)
(* Note: Ask Price Futures Depth Market Depth Level HF is chosen by Ask    *)
(* Price Futures Depth Opening, which every arm reads at the same place    *)
(* among fields of the same widths, and every value of it reads one of     *)
(* them: each arm is the same bytes, read as those bytes, and what the     *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Bid Price Quote Strategy Market Depth Level is chosen by Bid      *)
(* Price Quote Opening, which every arm reads at the same place among      *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Ask Price Quote Strategy Market Depth Level is chosen by Ask      *)
(* Price Quote Opening, which every arm reads at the same place among      *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Maximum Threshold Price Fraction Pair is chosen by Maximum        *)
(* Threshold Price Fraction Indicator, which every arm reads at the same   *)
(* place among fields of the same widths, and every value of it reads one  *)
(* of them: each arm is the same bytes, read as those bytes, and what the  *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Minimum Threshold Price Instrument Fraction Pair is chosen by     *)
(* Minimum Threshold Price Fraction Indicator, which every arm reads at    *)
(* the same place among fields of the same widths, and every value of it   *)
(* reads one of them: each arm is the same bytes, read as those bytes, and *)
(* what the choice names is how they are read.                             *)
(*                                                                         *)
(* Note: Tick Increment is chosen by Tick Increment Fraction Indicator,    *)
(* which every arm reads at the same place among fields of the same        *)
(* widths, and every value of it reads one of them: each arm is the same   *)
(* bytes, read as those bytes, and what the choice names is how they are   *)
(* read.                                                                   *)
(*                                                                         *)
(* Note: Tick Value Fraction Pair is chosen by Tick Value Fraction         *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Maximum Threshold Price Futures Fraction Pair is chosen by        *)
(* Maximum Threshold Price Fraction Indicator, which every arm reads at    *)
(* the same place among fields of the same widths, and every value of it   *)
(* reads one of them: each arm is the same bytes, read as those bytes, and *)
(* what the choice names is how they are read.                             *)
(*                                                                         *)
(* Note: Minimum Threshold Price Futures Fraction Pair is chosen by        *)
(* Minimum Threshold Price Fraction Indicator, which every arm reads at    *)
(* the same place among fields of the same widths, and every value of it   *)
(* reads one of them: each arm is the same bytes, read as those bytes, and *)
(* what the choice names is how they are read.                             *)
(*                                                                         *)
(* Note: Minimum Threshold Price Strategy Fraction Pair is chosen by       *)
(* Minimum Threshold Price Fraction Indicator, which every arm reads at    *)
(* the same place among fields of the same widths, and every value of it   *)
(* reads one of them: each arm is the same bytes, read as those bytes, and *)
(* what the choice names is how they are read.                             *)
(*                                                                         *)
(* Note: Leg Ratio Or Delta Fraction Pair is chosen by Leg Ratio Or Delta  *)
(* Fraction Indicator, which every arm reads at the same place among       *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Leg Price Fraction Pair is chosen by Leg Price Fraction           *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Initial Order Price Fraction Pair is chosen by Initial Order      *)
(* Price Fraction Indicator, which every arm reads at the same place among *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Bid Price Summary Fraction Pair is chosen by Bid Price Fraction   *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Ask Price Summary Fraction Pair is chosen by Ask Price Fraction   *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Last Price Fraction Pair is chosen by Last Price Fraction         *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Net Change Option Summary Message Fraction Pair is chosen by Net  *)
(* Change Fraction Indicator, which every arm reads at the same place      *)
(* among fields of the same widths, and every value of it reads one of     *)
(* them: each arm is the same bytes, read as those bytes, and what the     *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Open Price Fraction Pair is chosen by Open Price Fraction         *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: High Price Fraction Pair is chosen by High Price Fraction         *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Low Price Fraction Pair is chosen by Low Price Fraction           *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Closing Price Fraction Pair is chosen by Closing Price Fraction   *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Previous Closing Price Fraction Pair is chosen by Previous        *)
(* Closing Price Fraction Indicator, which every arm reads at the same     *)
(* place among fields of the same widths, and every value of it reads one  *)
(* of them: each arm is the same bytes, read as those bytes, and what the  *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Net Change Future Options Summary Message Fraction Pair is chosen *)
(* by Net Change Fraction Indicator, which every arm reads at the same     *)
(* place among fields of the same widths, and every value of it reads one  *)
(* of them: each arm is the same bytes, read as those bytes, and what the  *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Opening Price Fraction Pair is chosen by Opening Price Fraction   *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Settlement Price Fraction Pair is chosen by Settlement Price      *)
(* Fraction Indicator, which every arm reads at the same place among       *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Previous Settlement Price Fraction Pair is chosen by Previous     *)
(* Settlement Price Fraction Indicator, which every arm reads at the same  *)
(* place among fields of the same widths, and every value of it reads one  *)
(* of them: each arm is the same bytes, read as those bytes, and what the  *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Net Change Futures Summary Message Fraction Pair is chosen by Net *)
(* Change Fraction Indicator, which every arm reads at the same place      *)
(* among fields of the same widths, and every value of it reads one of     *)
(* them: each arm is the same bytes, read as those bytes, and what the     *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Previous Settlement Fraction Pair is chosen by Previous           *)
(* Settlement Fraction Indicator, which every arm reads at the same place  *)
(* among fields of the same widths, and every value of it reads one of     *)
(* them: each arm is the same bytes, read as those bytes, and what the     *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: External Price At Source Fraction Pair is chosen by External      *)
(* Price Fraction Indicator, which every arm reads at the same place among *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Net Change Strategy Summary Message Fraction Pair is chosen by    *)
(* Net Change Fraction Indicator, which every arm reads at the same place  *)
(* among fields of the same widths, and every value of it reads one of     *)
(* them: each arm is the same bytes, read as those bytes, and what the     *)
(* choice names is how they are read.                                      *)
(*                                                                         *)
(* Note: Order Price Fraction Pair is chosen by Order Price Fraction       *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Net Change Futures Trade Correction Message Fraction Pair is      *)
(* chosen by Net Change Fraction Indicator, which every arm reads at the   *)
(* same place among fields of the same widths, and every value of it reads *)
(* one of them: each arm is the same bytes, read as those bytes, and what  *)
(* the choice names is how they are read.                                  *)
(*                                                                         *)
(* Note: Coupon Fraction Pair is chosen by Coupon Fraction Indicator,      *)
(* which every arm reads at the same place among fields of the same        *)
(* widths, and every value of it reads one of them: each arm is the same   *)
(* bytes, read as those bytes, and what the choice names is how they are   *)
(* read.                                                                   *)
(*                                                                         *)
(* Note: Conversion Factor Fraction Pair is chosen by Conversion Factor    *)
(* Fraction Indicator, which every arm reads at the same place among       *)
(* fields of the same widths, and every value of it reads one of them:     *)
(* each arm is the same bytes, read as those bytes, and what the choice    *)
(* names is how they are read.                                             *)
(*                                                                         *)
(* Note: Min Price Fraction Pair is chosen by Min Price Fraction           *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Tick Price Fraction Pair is chosen by Tick Price Fraction         *)
(* Indicator, which every arm reads at the same place among fields of the  *)
(* same widths, and every value of it reads one of them: each arm is the   *)
(* same bytes, read as those bytes, and what the choice names is how they  *)
(* are read.                                                               *)
(*                                                                         *)
(* Note: Sola Frame is of no one width: each is read by its own fields,    *)
(* and since every reading of it takes at least 35 bytes off the reader    *)
(* the run ends where the data does.                                       *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol ==
    { ZeroOptionSymbol }
        \cup { [ZeroOptionSymbol EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Trade Message: 60 bytes                                          *)
(***************************************************************************)

OptionTradeMessage ==
    [ exchangeId             : Sample(1),
      optionSymbol           : OptionSymbol,
      volume                 : Sample(8),
      tradePriceFractionPair : Sample(8),
      netChangeSign          : Sample(1),
      netChangeFractionPair  : Sample(8),
      priceIndicatorMarker   : Sample(1),
      tradeNumber            : Sample(8),
      auctionId              : Sample(6) ]

EncodeOptionTradeMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol(message.optionSymbol)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.netChangeSign
        \o message.netChangeFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber
        \o message.auctionId

DecodeOptionTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(optionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(netChangeFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         optionSymbol           |-> optionSymbol.value,
         volume                 |-> volume.value,
         tradePriceFractionPair |-> tradePriceFractionPair.value,
         netChangeSign          |-> netChangeSign.value,
         netChangeFractionPair  |-> netChangeFractionPair.value,
         priceIndicatorMarker   |-> priceIndicatorMarker.value,
         tradeNumber            |-> tradeNumber.value,
         auctionId              |-> auctionId.value ], auctionId.rest)

ZeroOptionTradeMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol           |-> ZeroOptionSymbol,
      volume                 |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      netChangeSign          |-> [i \in 1 .. 1 |-> 0],
      netChangeFractionPair  |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker   |-> [i \in 1 .. 1 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0] ]

(* Option Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeMessage ==
    { ZeroOptionTradeMessage }
        \cup { [ZeroOptionTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol }
        \cup { [ZeroOptionTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.netChangeFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol ==
    { ZeroFutureOptionSymbol }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Trade Message: 61 bytes                                  *)
(***************************************************************************)

FutureOptionsTradeMessage ==
    [ exchangeId                                     : Sample(1),
      futureOptionSymbol                             : FutureOptionSymbol,
      volume                                         : Sample(8),
      tradePriceFractionPair                         : Sample(8),
      priceIndicatorMarker                           : Sample(1),
      netChangeSign                                  : Sample(1),
      netChangeFutureOptionsTradeMessageFractionPair : Sample(8),
      tradeNumber                                    : Sample(8),
      auctionId                                      : Sample(6) ]

EncodeFutureOptionsTradeMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol(message.futureOptionSymbol)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.priceIndicatorMarker
        \o message.netChangeSign
        \o message.netChangeFutureOptionsTradeMessageFractionPair
        \o message.tradeNumber
        \o message.auctionId

DecodeFutureOptionsTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(priceIndicatorMarker.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFutureOptionsTradeMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFutureOptionsTradeMessageFractionPair.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(netChangeFutureOptionsTradeMessageFractionPair.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId                                     |-> exchangeId.value,
         futureOptionSymbol                             |-> futureOptionSymbol.value,
         volume                                         |-> volume.value,
         tradePriceFractionPair                         |-> tradePriceFractionPair.value,
         priceIndicatorMarker                           |-> priceIndicatorMarker.value,
         netChangeSign                                  |-> netChangeSign.value,
         netChangeFutureOptionsTradeMessageFractionPair |-> netChangeFutureOptionsTradeMessageFractionPair.value,
         tradeNumber                                    |-> tradeNumber.value,
         auctionId                                      |-> auctionId.value ], auctionId.rest)

ZeroFutureOptionsTradeMessage ==
    [ exchangeId                                     |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol                             |-> ZeroFutureOptionSymbol,
      volume                                         |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair                         |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker                           |-> [i \in 1 .. 1 |-> 0],
      netChangeSign                                  |-> [i \in 1 .. 1 |-> 0],
      netChangeFutureOptionsTradeMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      tradeNumber                                    |-> [i \in 1 .. 8 |-> 0],
      auctionId                                      |-> [i \in 1 .. 6 |-> 0] ]

(* Future Options Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeMessage ==
    { ZeroFutureOptionsTradeMessage }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.netChangeFutureOptionsTradeMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct ==
    { ZeroFutureProduct }
        \cup { [ZeroFutureProduct EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Trade Message: 52 bytes                                         *)
(***************************************************************************)

FuturesTradeMessage ==
    [ exchangeId                               : Sample(1),
      futureProduct                            : FutureProduct,
      volume                                   : Sample(8),
      tradePriceFractionPair                   : Sample(8),
      netChangeSign                            : Sample(1),
      netChangeFuturesTradeMessageFractionPair : Sample(8),
      priceIndicatorMarker                     : Sample(1),
      tradeNumber                              : Sample(8),
      auctionId                                : Sample(6) ]

EncodeFuturesTradeMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct(message.futureProduct)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.netChangeSign
        \o message.netChangeFuturesTradeMessageFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber
        \o message.auctionId

DecodeFuturesTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET volume == ReadBytes(futureProduct.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFuturesTradeMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFuturesTradeMessageFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(netChangeFuturesTradeMessageFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId                               |-> exchangeId.value,
         futureProduct                            |-> futureProduct.value,
         volume                                   |-> volume.value,
         tradePriceFractionPair                   |-> tradePriceFractionPair.value,
         netChangeSign                            |-> netChangeSign.value,
         netChangeFuturesTradeMessageFractionPair |-> netChangeFuturesTradeMessageFractionPair.value,
         priceIndicatorMarker                     |-> priceIndicatorMarker.value,
         tradeNumber                              |-> tradeNumber.value,
         auctionId                                |-> auctionId.value ], auctionId.rest)

ZeroFuturesTradeMessage ==
    [ exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      futureProduct                            |-> ZeroFutureProduct,
      volume                                   |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair                   |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                            |-> [i \in 1 .. 1 |-> 0],
      netChangeFuturesTradeMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker                     |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                              |-> [i \in 1 .. 8 |-> 0],
      auctionId                                |-> [i \in 1 .. 6 |-> 0] ]

(* Futures Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeMessage ==
    { ZeroFuturesTradeMessage }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.netChangeFuturesTradeMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Strategy Trade Message: 72 bytes                                        *)
(***************************************************************************)

StrategyTradeMessage ==
    [ exchangeId             : Sample(1),
      symbol                 : Sample(30),
      volume                 : Sample(8),
      tradePriceSign         : Sample(1),
      tradePriceFractionPair : Sample(8),
      netChangeSign          : Sample(1),
      netChangeFractionPair  : Sample(8),
      priceIndicatorMarker   : Sample(1),
      tradeNumber            : Sample(8),
      auctionId              : Sample(6) ]

EncodeStrategyTradeMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePriceFractionPair
        \o message.netChangeSign
        \o message.netChangeFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber
        \o message.auctionId

DecodeStrategyTradeMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(tradePriceSign.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(netChangeFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         symbol                 |-> symbol.value,
         volume                 |-> volume.value,
         tradePriceSign         |-> tradePriceSign.value,
         tradePriceFractionPair |-> tradePriceFractionPair.value,
         netChangeSign          |-> netChangeSign.value,
         netChangeFractionPair  |-> netChangeFractionPair.value,
         priceIndicatorMarker   |-> priceIndicatorMarker.value,
         tradeNumber            |-> tradeNumber.value,
         auctionId              |-> auctionId.value ], auctionId.rest)

ZeroStrategyTradeMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 30 |-> 0],
      volume                 |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign         |-> [i \in 1 .. 1 |-> 0],
      tradePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      netChangeSign          |-> [i \in 1 .. 1 |-> 0],
      netChangeFractionPair  |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker   |-> [i \in 1 .. 1 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0] ]

(* Strategy Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeMessage ==
    { ZeroStrategyTradeMessage }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.netChangeFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol2 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol2(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol2(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol2 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol2 ==
    { ZeroOptionSymbol2 }
        \cup { [ZeroOptionSymbol2 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol2 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Request For Quote Message: 29 bytes                              *)
(***************************************************************************)

OptionRequestForQuoteMessage ==
    [ exchangeId          : Sample(1),
      optionSymbol        : OptionSymbol2,
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeOptionRequestForQuoteMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol2(message.optionSymbol)
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeOptionRequestForQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol2(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(optionSymbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId          |-> exchangeId.value,
         optionSymbol        |-> optionSymbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroOptionRequestForQuoteMessage ==
    [ exchangeId          |-> [i \in 1 .. 1 |-> 0],
      optionSymbol        |-> ZeroOptionSymbol2,
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Option Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionRequestForQuoteMessage ==
    { ZeroOptionRequestForQuoteMessage }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol2 }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroOptionRequestForQuoteMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol2 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol2(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol2(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol2 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol2 ==
    { ZeroFutureOptionSymbol2 }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol2 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Request For Quote Message: 30 bytes                      *)
(***************************************************************************)

FutureOptionsRequestForQuoteMessage ==
    [ exchangeId          : Sample(1),
      futureOptionSymbol  : FutureOptionSymbol2,
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeFutureOptionsRequestForQuoteMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol2(message.futureOptionSymbol)
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeFutureOptionsRequestForQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol2(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId          |-> exchangeId.value,
         futureOptionSymbol  |-> futureOptionSymbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroFutureOptionsRequestForQuoteMessage ==
    [ exchangeId          |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol  |-> ZeroFutureOptionSymbol2,
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsRequestForQuoteMessage ==
    { ZeroFutureOptionsRequestForQuoteMessage }
        \cup { [ZeroFutureOptionsRequestForQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsRequestForQuoteMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol2 }
        \cup { [ZeroFutureOptionsRequestForQuoteMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsRequestForQuoteMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct2 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct2(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct2(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct2 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct2 ==
    { ZeroFutureProduct2 }
        \cup { [ZeroFutureProduct2 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct2 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct2 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct2 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Future Request For Quote Message: 21 bytes                              *)
(***************************************************************************)

FutureRequestForQuoteMessage ==
    [ exchangeId          : Sample(1),
      futureProduct       : FutureProduct2,
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeFutureRequestForQuoteMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct2(message.futureProduct)
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeFutureRequestForQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct2(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(futureProduct.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId          |-> exchangeId.value,
         futureProduct       |-> futureProduct.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroFutureRequestForQuoteMessage ==
    [ exchangeId          |-> [i \in 1 .. 1 |-> 0],
      futureProduct       |-> ZeroFutureProduct2,
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Future Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureRequestForQuoteMessage ==
    { ZeroFutureRequestForQuoteMessage }
        \cup { [ZeroFutureRequestForQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureRequestForQuoteMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct2 }
        \cup { [ZeroFutureRequestForQuoteMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureRequestForQuoteMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Request For Quote Message: 40 bytes                            *)
(***************************************************************************)

StrategyRequestForQuoteMessage ==
    [ exchangeId          : Sample(1),
      symbol              : Sample(30),
      requestedSize       : Sample(8),
      requestedMarketSide : Sample(1) ]

EncodeStrategyRequestForQuoteMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.requestedSize
        \o message.requestedMarketSide

DecodeStrategyRequestForQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET requestedSize == ReadBytes(symbol.rest, 8) IN IF ~requestedSize.ok THEN Fail ELSE
    LET requestedMarketSide == ReadBytes(requestedSize.rest, 1) IN IF ~requestedMarketSide.ok THEN Fail ELSE
    Ok([ exchangeId          |-> exchangeId.value,
         symbol              |-> symbol.value,
         requestedSize       |-> requestedSize.value,
         requestedMarketSide |-> requestedMarketSide.value ], requestedMarketSide.rest)

ZeroStrategyRequestForQuoteMessage ==
    [ exchangeId          |-> [i \in 1 .. 1 |-> 0],
      symbol              |-> [i \in 1 .. 30 |-> 0],
      requestedSize       |-> [i \in 1 .. 8 |-> 0],
      requestedMarketSide |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Request For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyRequestForQuoteMessage ==
    { ZeroStrategyRequestForQuoteMessage }
        \cup { [ZeroStrategyRequestForQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyRequestForQuoteMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyRequestForQuoteMessage EXCEPT !.requestedSize = one] : one \in Sample(8) }
        \cup { [ZeroStrategyRequestForQuoteMessage EXCEPT !.requestedMarketSide = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Symbol Schedule Notice: 19 bytes                                 *)
(***************************************************************************)

OptionSymbolScheduleNotice ==
    [ rootSymbol                            : Sample(6),
      expiryMonth                           : Sample(1),
      strikePriceScheduleNoticeFractionPair : Sample(8),
      expiryYear                            : Sample(2),
      expiryDay                             : Sample(2) ]

EncodeOptionSymbolScheduleNotice(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceScheduleNoticeFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbolScheduleNotice(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceScheduleNoticeFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceScheduleNoticeFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceScheduleNoticeFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol                            |-> rootSymbol.value,
         expiryMonth                           |-> expiryMonth.value,
         strikePriceScheduleNoticeFractionPair |-> strikePriceScheduleNoticeFractionPair.value,
         expiryYear                            |-> expiryYear.value,
         expiryDay                             |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbolScheduleNotice ==
    [ rootSymbol                            |-> [i \in 1 .. 6 |-> 0],
      expiryMonth                           |-> [i \in 1 .. 1 |-> 0],
      strikePriceScheduleNoticeFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear                            |-> [i \in 1 .. 2 |-> 0],
      expiryDay                             |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol Schedule Notice at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbolScheduleNotice ==
    { ZeroOptionSymbolScheduleNotice }
        \cup { [ZeroOptionSymbolScheduleNotice EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbolScheduleNotice EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbolScheduleNotice EXCEPT !.strikePriceScheduleNoticeFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbolScheduleNotice EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbolScheduleNotice EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Schedule Notice Option Message: 27 bytes                     *)
(***************************************************************************)

InstrumentScheduleNoticeOptionMessage ==
    [ exchangeId                 : Sample(1),
      optionSymbolScheduleNotice : OptionSymbolScheduleNotice,
      seriesStatus               : Sample(1),
      scheduledStatusChangeTime  : Sample(6) ]

EncodeInstrumentScheduleNoticeOptionMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbolScheduleNotice(message.optionSymbolScheduleNotice)
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeOptionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbolScheduleNotice == DecodeOptionSymbolScheduleNotice(exchangeId.rest) IN IF ~optionSymbolScheduleNotice.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(optionSymbolScheduleNotice.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                 |-> exchangeId.value,
         optionSymbolScheduleNotice |-> optionSymbolScheduleNotice.value,
         seriesStatus               |-> seriesStatus.value,
         scheduledStatusChangeTime  |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeOptionMessage ==
    [ exchangeId                 |-> [i \in 1 .. 1 |-> 0],
      optionSymbolScheduleNotice |-> ZeroOptionSymbolScheduleNotice,
      seriesStatus               |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime  |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Option Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeOptionMessage ==
    { ZeroInstrumentScheduleNoticeOptionMessage }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.optionSymbolScheduleNotice = one] : one \in CheckedOptionSymbolScheduleNotice }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeOptionMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol3 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol3(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol3(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol3 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol3 ==
    { ZeroFutureOptionSymbol3 }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol3 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Schedule Notice Futures Option Message: 28 bytes             *)
(***************************************************************************)

InstrumentScheduleNoticeFuturesOptionMessage ==
    [ exchangeId                : Sample(1),
      futureOptionSymbol        : FutureOptionSymbol3,
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeFuturesOptionMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol3(message.futureOptionSymbol)
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeFuturesOptionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol3(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(futureOptionSymbol.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         futureOptionSymbol        |-> futureOptionSymbol.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeFuturesOptionMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol        |-> ZeroFutureOptionSymbol3,
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Futures Option Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeFuturesOptionMessage ==
    { ZeroInstrumentScheduleNoticeFuturesOptionMessage }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol3 }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFuturesOptionMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct3 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct3(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct3(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct3 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct3 ==
    { ZeroFutureProduct3 }
        \cup { [ZeroFutureProduct3 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct3 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct3 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct3 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Schedule Notice Future Message: 19 bytes                     *)
(***************************************************************************)

InstrumentScheduleNoticeFutureMessage ==
    [ exchangeId                : Sample(1),
      futureProduct             : FutureProduct3,
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeFutureMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct3(message.futureProduct)
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeFutureMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct3(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(futureProduct.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         futureProduct             |-> futureProduct.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeFutureMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      futureProduct             |-> ZeroFutureProduct3,
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Future Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeFutureMessage ==
    { ZeroInstrumentScheduleNoticeFutureMessage }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct3 }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeFutureMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Instrument Schedule Notice Strategy Message: 38 bytes                   *)
(***************************************************************************)

InstrumentScheduleNoticeStrategyMessage ==
    [ exchangeId                : Sample(1),
      strategySymbol            : Sample(30),
      seriesStatus              : Sample(1),
      scheduledStatusChangeTime : Sample(6) ]

EncodeInstrumentScheduleNoticeStrategyMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.seriesStatus
        \o message.scheduledStatusChangeTime

DecodeInstrumentScheduleNoticeStrategyMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET seriesStatus == ReadBytes(strategySymbol.rest, 1) IN IF ~seriesStatus.ok THEN Fail ELSE
    LET scheduledStatusChangeTime == ReadBytes(seriesStatus.rest, 6) IN IF ~scheduledStatusChangeTime.ok THEN Fail ELSE
    Ok([ exchangeId                |-> exchangeId.value,
         strategySymbol            |-> strategySymbol.value,
         seriesStatus              |-> seriesStatus.value,
         scheduledStatusChangeTime |-> scheduledStatusChangeTime.value ], scheduledStatusChangeTime.rest)

ZeroInstrumentScheduleNoticeStrategyMessage ==
    [ exchangeId                |-> [i \in 1 .. 1 |-> 0],
      strategySymbol            |-> [i \in 1 .. 30 |-> 0],
      seriesStatus              |-> [i \in 1 .. 1 |-> 0],
      scheduledStatusChangeTime |-> [i \in 1 .. 6 |-> 0] ]

(* Instrument Schedule Notice Strategy Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentScheduleNoticeStrategyMessage ==
    { ZeroInstrumentScheduleNoticeStrategyMessage }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.seriesStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentScheduleNoticeStrategyMessage EXCEPT !.scheduledStatusChangeTime = one] : one \in Sample(6) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol3 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol3(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol3(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol3 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol3 ==
    { ZeroOptionSymbol3 }
        \cup { [ZeroOptionSymbol3 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol3 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Quote Message: 47 bytes                                          *)
(***************************************************************************)

OptionQuoteMessage ==
    [ exchangeId             : Sample(1),
      optionSymbol           : OptionSymbol3,
      bidPriceQuote          : Sample(8),
      bidSize                : Sample(5),
      askPriceQuote          : Sample(8),
      askSize                : Sample(5),
      instrumentStatusMarker : Sample(1) ]

EncodeOptionQuoteMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol3(message.optionSymbol)
        \o message.bidPriceQuote
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeOptionQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol3(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(optionSymbol.rest, 8) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuote.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 8) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuote.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         optionSymbol           |-> optionSymbol.value,
         bidPriceQuote          |-> bidPriceQuote.value,
         bidSize                |-> bidSize.value,
         askPriceQuote          |-> askPriceQuote.value,
         askSize                |-> askSize.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroOptionQuoteMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol           |-> ZeroOptionSymbol3,
      bidPriceQuote          |-> [i \in 1 .. 8 |-> 0],
      bidSize                |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote          |-> [i \in 1 .. 8 |-> 0],
      askSize                |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0] ]

(* Option Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionQuoteMessage ==
    { ZeroOptionQuoteMessage }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol3 }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(8) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(8) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol4 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol4(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol4(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol4 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol4 ==
    { ZeroFutureOptionSymbol4 }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol4 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Quote Message: 48 bytes                                  *)
(***************************************************************************)

FutureOptionsQuoteMessage ==
    [ exchangeId             : Sample(1),
      futureOptionSymbol     : FutureOptionSymbol4,
      bidPriceQuote          : Sample(8),
      bidSize                : Sample(5),
      askPriceQuote          : Sample(8),
      askSize                : Sample(5),
      instrumentStatusMarker : Sample(1) ]

EncodeFutureOptionsQuoteMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol4(message.futureOptionSymbol)
        \o message.bidPriceQuote
        \o message.bidSize
        \o message.askPriceQuote
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeFutureOptionsQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol4(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuote.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(bidSize.rest, 8) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuote.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         futureOptionSymbol     |-> futureOptionSymbol.value,
         bidPriceQuote          |-> bidPriceQuote.value,
         bidSize                |-> bidSize.value,
         askPriceQuote          |-> askPriceQuote.value,
         askSize                |-> askSize.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroFutureOptionsQuoteMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol     |-> ZeroFutureOptionSymbol4,
      bidPriceQuote          |-> [i \in 1 .. 8 |-> 0],
      bidSize                |-> [i \in 1 .. 5 |-> 0],
      askPriceQuote          |-> [i \in 1 .. 8 |-> 0],
      askSize                |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsQuoteMessage ==
    { ZeroFutureOptionsQuoteMessage }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol4 }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct4 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct4(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct4(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct4 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct4 ==
    { ZeroFutureProduct4 }
        \cup { [ZeroFutureProduct4 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct4 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct4 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct4 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Quote Message: 39 bytes                                         *)
(***************************************************************************)

FuturesQuoteMessage ==
    [ exchangeId                       : Sample(1),
      futureProduct                    : FutureProduct4,
      bidPriceQuoteFuturesQuoteMessage : Sample(8),
      bidSize                          : Sample(5),
      askPriceQuoteFuturesQuoteMessage : Sample(8),
      askSize                          : Sample(5),
      instrumentStatusMarker           : Sample(1) ]

EncodeFuturesQuoteMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct4(message.futureProduct)
        \o message.bidPriceQuoteFuturesQuoteMessage
        \o message.bidSize
        \o message.askPriceQuoteFuturesQuoteMessage
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeFuturesQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct4(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET bidPriceQuoteFuturesQuoteMessage == ReadBytes(futureProduct.rest, 8) IN IF ~bidPriceQuoteFuturesQuoteMessage.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuoteFuturesQuoteMessage.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceQuoteFuturesQuoteMessage == ReadBytes(bidSize.rest, 8) IN IF ~askPriceQuoteFuturesQuoteMessage.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuoteFuturesQuoteMessage.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId                       |-> exchangeId.value,
         futureProduct                    |-> futureProduct.value,
         bidPriceQuoteFuturesQuoteMessage |-> bidPriceQuoteFuturesQuoteMessage.value,
         bidSize                          |-> bidSize.value,
         askPriceQuoteFuturesQuoteMessage |-> askPriceQuoteFuturesQuoteMessage.value,
         askSize                          |-> askSize.value,
         instrumentStatusMarker           |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroFuturesQuoteMessage ==
    [ exchangeId                       |-> [i \in 1 .. 1 |-> 0],
      futureProduct                    |-> ZeroFutureProduct4,
      bidPriceQuoteFuturesQuoteMessage |-> [i \in 1 .. 8 |-> 0],
      bidSize                          |-> [i \in 1 .. 5 |-> 0],
      askPriceQuoteFuturesQuoteMessage |-> [i \in 1 .. 8 |-> 0],
      askSize                          |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker           |-> [i \in 1 .. 1 |-> 0] ]

(* Futures Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesQuoteMessage ==
    { ZeroFuturesQuoteMessage }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct4 }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidPriceQuoteFuturesQuoteMessage = one] : one \in Sample(8) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askPriceQuoteFuturesQuoteMessage = one] : one \in Sample(8) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Strategy Quote Message: 60 bytes                                        *)
(***************************************************************************)

StrategyQuoteMessage ==
    [ exchangeId             : Sample(1),
      symbol                 : Sample(30),
      bidPriceSign           : Sample(1),
      bidPriceQuote          : Sample(8),
      bidSize                : Sample(5),
      askPriceSign           : Sample(1),
      askPriceQuote          : Sample(8),
      askSize                : Sample(5),
      instrumentStatusMarker : Sample(1) ]

EncodeStrategyQuoteMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.bidPriceSign
        \o message.bidPriceQuote
        \o message.bidSize
        \o message.askPriceSign
        \o message.askPriceQuote
        \o message.askSize
        \o message.instrumentStatusMarker

DecodeStrategyQuoteMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(symbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceQuote == ReadBytes(bidPriceSign.rest, 8) IN IF ~bidPriceQuote.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuote.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceQuote == ReadBytes(askPriceSign.rest, 8) IN IF ~askPriceQuote.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuote.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(askSize.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         symbol                 |-> symbol.value,
         bidPriceSign           |-> bidPriceSign.value,
         bidPriceQuote          |-> bidPriceQuote.value,
         bidSize                |-> bidSize.value,
         askPriceSign           |-> askPriceSign.value,
         askPriceQuote          |-> askPriceQuote.value,
         askSize                |-> askSize.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value ], instrumentStatusMarker.rest)

ZeroStrategyQuoteMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign           |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuote          |-> [i \in 1 .. 8 |-> 0],
      bidSize                |-> [i \in 1 .. 5 |-> 0],
      askPriceSign           |-> [i \in 1 .. 1 |-> 0],
      askPriceQuote          |-> [i \in 1 .. 8 |-> 0],
      askSize                |-> [i \in 1 .. 5 |-> 0],
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyQuoteMessage ==
    { ZeroStrategyQuoteMessage }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidPriceQuote = one] : one \in Sample(8) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askPriceQuote = one] : one \in Sample(8) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyQuoteMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol4 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol4(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol4(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol4 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol4 ==
    { ZeroOptionSymbol4 }
        \cup { [ZeroOptionSymbol4 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol4 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Market Depth Level: 31 bytes                                            *)
(***************************************************************************)

MarketDepthLevel ==
    [ levelOfMarketDepth            : Sample(1),
      bidPriceQuoteMarketDepthLevel : Sample(8),
      bidSize                       : Sample(5),
      numberOfBidOrders             : Sample(2),
      askPriceQuoteMarketDepthLevel : Sample(8),
      askSize                       : Sample(5),
      numberOfAskOrders             : Sample(2) ]

EncodeMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuoteMarketDepthLevel
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuoteMarketDepthLevel
        \o message.askSize
        \o message.numberOfAskOrders

DecodeMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuoteMarketDepthLevel == ReadBytes(levelOfMarketDepth.rest, 8) IN IF ~bidPriceQuoteMarketDepthLevel.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuoteMarketDepthLevel.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuoteMarketDepthLevel == ReadBytes(numberOfBidOrders.rest, 8) IN IF ~askPriceQuoteMarketDepthLevel.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuoteMarketDepthLevel.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth            |-> levelOfMarketDepth.value,
         bidPriceQuoteMarketDepthLevel |-> bidPriceQuoteMarketDepthLevel.value,
         bidSize                       |-> bidSize.value,
         numberOfBidOrders             |-> numberOfBidOrders.value,
         askPriceQuoteMarketDepthLevel |-> askPriceQuoteMarketDepthLevel.value,
         askSize                       |-> askSize.value,
         numberOfAskOrders             |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroMarketDepthLevel ==
    [ levelOfMarketDepth            |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuoteMarketDepthLevel |-> [i \in 1 .. 8 |-> 0],
      bidSize                       |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders             |-> [i \in 1 .. 2 |-> 0],
      askPriceQuoteMarketDepthLevel |-> [i \in 1 .. 8 |-> 0],
      askSize                       |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders             |-> [i \in 1 .. 2 |-> 0] ]

(* Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedMarketDepthLevel ==
    { ZeroMarketDepthLevel }
        \cup { [ZeroMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidPriceQuoteMarketDepthLevel = one] : one \in Sample(8) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askPriceQuoteMarketDepthLevel = one] : one \in Sample(8) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Market Depth Level, written one after another *)
RECURSIVE EncodeMarketDepthLevelList(_)
EncodeMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDepthLevel(Head(messages)) \o EncodeMarketDepthLevelList(Tail(messages))

(* As many Market Depth Level as the field that counts them says *)
RECURSIVE ReadMarketDepthLevelList(_, _)
ReadMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Depth Level of each kind, for the lists that carry them *)
OneMarketDepthLevel == { ZeroMarketDepthLevel }

(***************************************************************************)
(* Option Market Depth Message                                             *)
(***************************************************************************)

OptionMarketDepthMessage ==
    [ exchangeId             : Sample(1),
      optionSymbol           : OptionSymbol4,
      instrumentStatusMarker : Sample(1),
      marketDepthLevel       : SampleLists(OneMarketDepthLevel) ]

EncodeOptionMarketDepthMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol4(message.optionSymbol)
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.marketDepthLevel), 1)
        \o EncodeMarketDepthLevelList(message.marketDepthLevel)

DecodeOptionMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol4(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(optionSymbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevels == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevels.ok THEN Fail ELSE
    LET marketDepthLevel == ReadMarketDepthLevelList(numberOfLevels.rest, numberOfLevels.value) IN IF ~marketDepthLevel.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         optionSymbol           |-> optionSymbol.value,
         instrumentStatusMarker |-> instrumentStatusMarker.value,
         marketDepthLevel       |-> marketDepthLevel.value ], marketDepthLevel.rest)

ZeroOptionMarketDepthMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol           |-> ZeroOptionSymbol4,
      instrumentStatusMarker |-> [i \in 1 .. 1 |-> 0],
      marketDepthLevel       |-> << >> ]

(* Option Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionMarketDepthMessage ==
    { ZeroOptionMarketDepthMessage }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol4 }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionMarketDepthMessage EXCEPT !.marketDepthLevel = one] : one \in SampleLists(OneMarketDepthLevel) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol5 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol5(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol5(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol5 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol5 ==
    { ZeroFutureOptionSymbol5 }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol5 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Market Depth Level: 31 bytes                             *)
(***************************************************************************)

FutureOptionsMarketDepthLevel ==
    [ levelOfMarketDepth              : Sample(1),
      bidPriceQuoteMarketDepthLevelHb : Sample(8),
      bidSize                         : Sample(5),
      numberOfBidOrders               : Sample(2),
      askPriceQuoteMarketDepthLevelHb : Sample(8),
      askSize                         : Sample(5),
      numberOfAskOrders               : Sample(2) ]

EncodeFutureOptionsMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuoteMarketDepthLevelHb
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceQuoteMarketDepthLevelHb
        \o message.askSize
        \o message.numberOfAskOrders

DecodeFutureOptionsMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuoteMarketDepthLevelHb == ReadBytes(levelOfMarketDepth.rest, 8) IN IF ~bidPriceQuoteMarketDepthLevelHb.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuoteMarketDepthLevelHb.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceQuoteMarketDepthLevelHb == ReadBytes(numberOfBidOrders.rest, 8) IN IF ~askPriceQuoteMarketDepthLevelHb.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuoteMarketDepthLevelHb.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth              |-> levelOfMarketDepth.value,
         bidPriceQuoteMarketDepthLevelHb |-> bidPriceQuoteMarketDepthLevelHb.value,
         bidSize                         |-> bidSize.value,
         numberOfBidOrders               |-> numberOfBidOrders.value,
         askPriceQuoteMarketDepthLevelHb |-> askPriceQuoteMarketDepthLevelHb.value,
         askSize                         |-> askSize.value,
         numberOfAskOrders               |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroFutureOptionsMarketDepthLevel ==
    [ levelOfMarketDepth              |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuoteMarketDepthLevelHb |-> [i \in 1 .. 8 |-> 0],
      bidSize                         |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders               |-> [i \in 1 .. 2 |-> 0],
      askPriceQuoteMarketDepthLevelHb |-> [i \in 1 .. 8 |-> 0],
      askSize                         |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders               |-> [i \in 1 .. 2 |-> 0] ]

(* Future Options Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsMarketDepthLevel ==
    { ZeroFutureOptionsMarketDepthLevel }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.bidPriceQuoteMarketDepthLevelHb = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.askPriceQuoteMarketDepthLevelHb = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Future Options Market Depth Level, written one after another *)
RECURSIVE EncodeFutureOptionsMarketDepthLevelList(_)
EncodeFutureOptionsMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFutureOptionsMarketDepthLevel(Head(messages)) \o EncodeFutureOptionsMarketDepthLevelList(Tail(messages))

(* As many Future Options Market Depth Level as the field that counts them says *)
RECURSIVE ReadFutureOptionsMarketDepthLevelList(_, _)
ReadFutureOptionsMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFutureOptionsMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFutureOptionsMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Future Options Market Depth Level of each kind, for the lists that carry them *)
OneFutureOptionsMarketDepthLevel == { ZeroFutureOptionsMarketDepthLevel }

(***************************************************************************)
(* Future Options Market Depth Message                                     *)
(***************************************************************************)

FutureOptionsMarketDepthMessage ==
    [ exchangeId                    : Sample(1),
      futureOptionSymbol            : FutureOptionSymbol5,
      instrumentStatusMarker        : Sample(1),
      futureOptionsMarketDepthLevel : SampleLists(OneFutureOptionsMarketDepthLevel) ]

EncodeFutureOptionsMarketDepthMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol5(message.futureOptionSymbol)
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.futureOptionsMarketDepthLevel), 1)
        \o EncodeFutureOptionsMarketDepthLevelList(message.futureOptionsMarketDepthLevel)

DecodeFutureOptionsMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol5(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(futureOptionSymbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevels == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevels.ok THEN Fail ELSE
    LET futureOptionsMarketDepthLevel == ReadFutureOptionsMarketDepthLevelList(numberOfLevels.rest, numberOfLevels.value) IN IF ~futureOptionsMarketDepthLevel.ok THEN Fail ELSE
    Ok([ exchangeId                    |-> exchangeId.value,
         futureOptionSymbol            |-> futureOptionSymbol.value,
         instrumentStatusMarker        |-> instrumentStatusMarker.value,
         futureOptionsMarketDepthLevel |-> futureOptionsMarketDepthLevel.value ], futureOptionsMarketDepthLevel.rest)

ZeroFutureOptionsMarketDepthMessage ==
    [ exchangeId                    |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol            |-> ZeroFutureOptionSymbol5,
      instrumentStatusMarker        |-> [i \in 1 .. 1 |-> 0],
      futureOptionsMarketDepthLevel |-> << >> ]

(* Future Options Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsMarketDepthMessage ==
    { ZeroFutureOptionsMarketDepthMessage }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol5 }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsMarketDepthMessage EXCEPT !.futureOptionsMarketDepthLevel = one] : one \in SampleLists(OneFutureOptionsMarketDepthLevel) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct5 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct5(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct5(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct5 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct5 ==
    { ZeroFutureProduct5 }
        \cup { [ZeroFutureProduct5 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct5 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct5 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct5 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Market Depth Level: 31 bytes                                    *)
(***************************************************************************)

FuturesMarketDepthLevel ==
    [ levelOfMarketDepth                     : Sample(1),
      bidPriceQuoteMarketDepthLevelHf        : Sample(8),
      bidSize                                : Sample(5),
      numberOfBidOrders                      : Sample(2),
      askPriceFuturesDepthMarketDepthLevelHf : Sample(8),
      askSize                                : Sample(5),
      numberOfAskOrders                      : Sample(2) ]

EncodeFuturesMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceQuoteMarketDepthLevelHf
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceFuturesDepthMarketDepthLevelHf
        \o message.askSize
        \o message.numberOfAskOrders

DecodeFuturesMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceQuoteMarketDepthLevelHf == ReadBytes(levelOfMarketDepth.rest, 8) IN IF ~bidPriceQuoteMarketDepthLevelHf.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuoteMarketDepthLevelHf.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceFuturesDepthMarketDepthLevelHf == ReadBytes(numberOfBidOrders.rest, 8) IN IF ~askPriceFuturesDepthMarketDepthLevelHf.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceFuturesDepthMarketDepthLevelHf.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth                     |-> levelOfMarketDepth.value,
         bidPriceQuoteMarketDepthLevelHf        |-> bidPriceQuoteMarketDepthLevelHf.value,
         bidSize                                |-> bidSize.value,
         numberOfBidOrders                      |-> numberOfBidOrders.value,
         askPriceFuturesDepthMarketDepthLevelHf |-> askPriceFuturesDepthMarketDepthLevelHf.value,
         askSize                                |-> askSize.value,
         numberOfAskOrders                      |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroFuturesMarketDepthLevel ==
    [ levelOfMarketDepth                     |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuoteMarketDepthLevelHf        |-> [i \in 1 .. 8 |-> 0],
      bidSize                                |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders                      |-> [i \in 1 .. 2 |-> 0],
      askPriceFuturesDepthMarketDepthLevelHf |-> [i \in 1 .. 8 |-> 0],
      askSize                                |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders                      |-> [i \in 1 .. 2 |-> 0] ]

(* Futures Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedFuturesMarketDepthLevel ==
    { ZeroFuturesMarketDepthLevel }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.bidPriceQuoteMarketDepthLevelHf = one] : one \in Sample(8) }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.askPriceFuturesDepthMarketDepthLevelHf = one] : one \in Sample(8) }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Futures Market Depth Level, written one after another *)
RECURSIVE EncodeFuturesMarketDepthLevelList(_)
EncodeFuturesMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFuturesMarketDepthLevel(Head(messages)) \o EncodeFuturesMarketDepthLevelList(Tail(messages))

(* As many Futures Market Depth Level as the field that counts them says *)
RECURSIVE ReadFuturesMarketDepthLevelList(_, _)
ReadFuturesMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFuturesMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFuturesMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Futures Market Depth Level of each kind, for the lists that carry them *)
OneFuturesMarketDepthLevel == { ZeroFuturesMarketDepthLevel }

(***************************************************************************)
(* Futures Market Depth Message                                            *)
(***************************************************************************)

FuturesMarketDepthMessage ==
    [ exchangeId              : Sample(1),
      futureProduct           : FutureProduct5,
      instrumentStatusMarker  : Sample(1),
      futuresMarketDepthLevel : SampleLists(OneFuturesMarketDepthLevel) ]

EncodeFuturesMarketDepthMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct5(message.futureProduct)
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.futuresMarketDepthLevel), 1)
        \o EncodeFuturesMarketDepthLevelList(message.futuresMarketDepthLevel)

DecodeFuturesMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct5(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(futureProduct.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevels == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevels.ok THEN Fail ELSE
    LET futuresMarketDepthLevel == ReadFuturesMarketDepthLevelList(numberOfLevels.rest, numberOfLevels.value) IN IF ~futuresMarketDepthLevel.ok THEN Fail ELSE
    Ok([ exchangeId              |-> exchangeId.value,
         futureProduct           |-> futureProduct.value,
         instrumentStatusMarker  |-> instrumentStatusMarker.value,
         futuresMarketDepthLevel |-> futuresMarketDepthLevel.value ], futuresMarketDepthLevel.rest)

ZeroFuturesMarketDepthMessage ==
    [ exchangeId              |-> [i \in 1 .. 1 |-> 0],
      futureProduct           |-> ZeroFutureProduct5,
      instrumentStatusMarker  |-> [i \in 1 .. 1 |-> 0],
      futuresMarketDepthLevel |-> << >> ]

(* Futures Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesMarketDepthMessage ==
    { ZeroFuturesMarketDepthMessage }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct5 }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesMarketDepthMessage EXCEPT !.futuresMarketDepthLevel = one] : one \in SampleLists(OneFuturesMarketDepthLevel) }

(***************************************************************************)
(* Strategy Market Depth Level: 33 bytes                                   *)
(***************************************************************************)

StrategyMarketDepthLevel ==
    [ levelOfMarketDepth                    : Sample(1),
      bidPriceSign                          : Sample(1),
      bidPriceQuoteStrategyMarketDepthLevel : Sample(8),
      bidSize                               : Sample(5),
      numberOfBidOrders                     : Sample(2),
      askPriceSign                          : Sample(1),
      askPriceQuoteStrategyMarketDepthLevel : Sample(8),
      askSize                               : Sample(5),
      numberOfAskOrders                     : Sample(2) ]

EncodeStrategyMarketDepthLevel(message) ==
    message.levelOfMarketDepth
        \o message.bidPriceSign
        \o message.bidPriceQuoteStrategyMarketDepthLevel
        \o message.bidSize
        \o message.numberOfBidOrders
        \o message.askPriceSign
        \o message.askPriceQuoteStrategyMarketDepthLevel
        \o message.askSize
        \o message.numberOfAskOrders

DecodeStrategyMarketDepthLevel(bytes) ==
    LET levelOfMarketDepth == ReadBytes(bytes, 1) IN IF ~levelOfMarketDepth.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(levelOfMarketDepth.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceQuoteStrategyMarketDepthLevel == ReadBytes(bidPriceSign.rest, 8) IN IF ~bidPriceQuoteStrategyMarketDepthLevel.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceQuoteStrategyMarketDepthLevel.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET numberOfBidOrders == ReadBytes(bidSize.rest, 2) IN IF ~numberOfBidOrders.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(numberOfBidOrders.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceQuoteStrategyMarketDepthLevel == ReadBytes(askPriceSign.rest, 8) IN IF ~askPriceQuoteStrategyMarketDepthLevel.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceQuoteStrategyMarketDepthLevel.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET numberOfAskOrders == ReadBytes(askSize.rest, 2) IN IF ~numberOfAskOrders.ok THEN Fail ELSE
    Ok([ levelOfMarketDepth                    |-> levelOfMarketDepth.value,
         bidPriceSign                          |-> bidPriceSign.value,
         bidPriceQuoteStrategyMarketDepthLevel |-> bidPriceQuoteStrategyMarketDepthLevel.value,
         bidSize                               |-> bidSize.value,
         numberOfBidOrders                     |-> numberOfBidOrders.value,
         askPriceSign                          |-> askPriceSign.value,
         askPriceQuoteStrategyMarketDepthLevel |-> askPriceQuoteStrategyMarketDepthLevel.value,
         askSize                               |-> askSize.value,
         numberOfAskOrders                     |-> numberOfAskOrders.value ], numberOfAskOrders.rest)

ZeroStrategyMarketDepthLevel ==
    [ levelOfMarketDepth                    |-> [i \in 1 .. 1 |-> 0],
      bidPriceSign                          |-> [i \in 1 .. 1 |-> 0],
      bidPriceQuoteStrategyMarketDepthLevel |-> [i \in 1 .. 8 |-> 0],
      bidSize                               |-> [i \in 1 .. 5 |-> 0],
      numberOfBidOrders                     |-> [i \in 1 .. 2 |-> 0],
      askPriceSign                          |-> [i \in 1 .. 1 |-> 0],
      askPriceQuoteStrategyMarketDepthLevel |-> [i \in 1 .. 8 |-> 0],
      askSize                               |-> [i \in 1 .. 5 |-> 0],
      numberOfAskOrders                     |-> [i \in 1 .. 2 |-> 0] ]

(* Strategy Market Depth Level at zero, then each field in turn at the values it is checked at *)
CheckedStrategyMarketDepthLevel ==
    { ZeroStrategyMarketDepthLevel }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.levelOfMarketDepth = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidPriceQuoteStrategyMarketDepthLevel = one] : one \in Sample(8) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.numberOfBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askPriceQuoteStrategyMarketDepthLevel = one] : one \in Sample(8) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategyMarketDepthLevel EXCEPT !.numberOfAskOrders = one] : one \in Sample(2) }

(* A run of Strategy Market Depth Level, written one after another *)
RECURSIVE EncodeStrategyMarketDepthLevelList(_)
EncodeStrategyMarketDepthLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyMarketDepthLevel(Head(messages)) \o EncodeStrategyMarketDepthLevelList(Tail(messages))

(* As many Strategy Market Depth Level as the field that counts them says *)
RECURSIVE ReadStrategyMarketDepthLevelList(_, _)
ReadStrategyMarketDepthLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyMarketDepthLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyMarketDepthLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Market Depth Level of each kind, for the lists that carry them *)
OneStrategyMarketDepthLevel == { ZeroStrategyMarketDepthLevel }

(***************************************************************************)
(* Strategy Market Depth Message                                           *)
(***************************************************************************)

StrategyMarketDepthMessage ==
    [ exchangeId               : Sample(1),
      symbol                   : Sample(30),
      instrumentStatusMarker   : Sample(1),
      strategyMarketDepthLevel : SampleLists(OneStrategyMarketDepthLevel) ]

EncodeStrategyMarketDepthMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.instrumentStatusMarker
        \o EncodeDigits(Len(message.strategyMarketDepthLevel), 1)
        \o EncodeStrategyMarketDepthLevelList(message.strategyMarketDepthLevel)

DecodeStrategyMarketDepthMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentStatusMarker == ReadBytes(symbol.rest, 1) IN IF ~instrumentStatusMarker.ok THEN Fail ELSE
    LET numberOfLevels == ReadDigits(instrumentStatusMarker.rest, 1) IN IF ~numberOfLevels.ok THEN Fail ELSE
    LET strategyMarketDepthLevel == ReadStrategyMarketDepthLevelList(numberOfLevels.rest, numberOfLevels.value) IN IF ~strategyMarketDepthLevel.ok THEN Fail ELSE
    Ok([ exchangeId               |-> exchangeId.value,
         symbol                   |-> symbol.value,
         instrumentStatusMarker   |-> instrumentStatusMarker.value,
         strategyMarketDepthLevel |-> strategyMarketDepthLevel.value ], strategyMarketDepthLevel.rest)

ZeroStrategyMarketDepthMessage ==
    [ exchangeId               |-> [i \in 1 .. 1 |-> 0],
      symbol                   |-> [i \in 1 .. 30 |-> 0],
      instrumentStatusMarker   |-> [i \in 1 .. 1 |-> 0],
      strategyMarketDepthLevel |-> << >> ]

(* Strategy Market Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyMarketDepthMessage ==
    { ZeroStrategyMarketDepthMessage }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.instrumentStatusMarker = one] : one \in Sample(1) }
        \cup { [ZeroStrategyMarketDepthMessage EXCEPT !.strategyMarketDepthLevel = one] : one \in SampleLists(OneStrategyMarketDepthLevel) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol5 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol5(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol5(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol5 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol5 ==
    { ZeroOptionSymbol5 }
        \cup { [ZeroOptionSymbol5 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol5 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Trade Cancellation Message: 51 bytes                             *)
(***************************************************************************)

OptionTradeCancellationMessage ==
    [ exchangeId             : Sample(1),
      optionSymbol           : OptionSymbol5,
      volume                 : Sample(8),
      tradePriceFractionPair : Sample(8),
      priceIndicatorMarker   : Sample(1),
      tradeNumber            : Sample(8),
      auctionId              : Sample(6) ]

EncodeOptionTradeCancellationMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol5(message.optionSymbol)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber
        \o message.auctionId

DecodeOptionTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol5(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(optionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         optionSymbol           |-> optionSymbol.value,
         volume                 |-> volume.value,
         tradePriceFractionPair |-> tradePriceFractionPair.value,
         priceIndicatorMarker   |-> priceIndicatorMarker.value,
         tradeNumber            |-> tradeNumber.value,
         auctionId              |-> auctionId.value ], auctionId.rest)

ZeroOptionTradeCancellationMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol           |-> ZeroOptionSymbol5,
      volume                 |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker   |-> [i \in 1 .. 1 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0] ]

(* Option Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionTradeCancellationMessage ==
    { ZeroOptionTradeCancellationMessage }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol5 }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroOptionTradeCancellationMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol6 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol6(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol6(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol6 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol6 ==
    { ZeroFutureOptionSymbol6 }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol6 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Trade Cancellation Message: 52 bytes                     *)
(***************************************************************************)

FutureOptionsTradeCancellationMessage ==
    [ exchangeId             : Sample(1),
      futureOptionSymbol     : FutureOptionSymbol6,
      volume                 : Sample(8),
      tradePriceFractionPair : Sample(8),
      priceIndicatorMarker   : Sample(1),
      tradeNumber            : Sample(8),
      auctionId              : Sample(6) ]

EncodeFutureOptionsTradeCancellationMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol6(message.futureOptionSymbol)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber
        \o message.auctionId

DecodeFutureOptionsTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol6(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET volume == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         futureOptionSymbol     |-> futureOptionSymbol.value,
         volume                 |-> volume.value,
         tradePriceFractionPair |-> tradePriceFractionPair.value,
         priceIndicatorMarker   |-> priceIndicatorMarker.value,
         tradeNumber            |-> tradeNumber.value,
         auctionId              |-> auctionId.value ], auctionId.rest)

ZeroFutureOptionsTradeCancellationMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol     |-> ZeroFutureOptionSymbol6,
      volume                 |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker   |-> [i \in 1 .. 1 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0] ]

(* Future Options Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsTradeCancellationMessage ==
    { ZeroFutureOptionsTradeCancellationMessage }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol6 }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsTradeCancellationMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct6 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct6(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct6(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct6 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct6 ==
    { ZeroFutureProduct6 }
        \cup { [ZeroFutureProduct6 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct6 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct6 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct6 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Future Trade Cancellation Message: 43 bytes                             *)
(***************************************************************************)

FutureTradeCancellationMessage ==
    [ exchangeId             : Sample(1),
      futureProduct          : FutureProduct6,
      volume                 : Sample(8),
      tradePriceFractionPair : Sample(8),
      priceIndicatorMarker   : Sample(1),
      tradeNumber            : Sample(8),
      auctionId              : Sample(6) ]

EncodeFutureTradeCancellationMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct6(message.futureProduct)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber
        \o message.auctionId

DecodeFutureTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct6(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET volume == ReadBytes(futureProduct.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         futureProduct          |-> futureProduct.value,
         volume                 |-> volume.value,
         tradePriceFractionPair |-> tradePriceFractionPair.value,
         priceIndicatorMarker   |-> priceIndicatorMarker.value,
         tradeNumber            |-> tradeNumber.value,
         auctionId              |-> auctionId.value ], auctionId.rest)

ZeroFutureTradeCancellationMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      futureProduct          |-> ZeroFutureProduct6,
      volume                 |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker   |-> [i \in 1 .. 1 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0] ]

(* Future Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureTradeCancellationMessage ==
    { ZeroFutureTradeCancellationMessage }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct6 }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroFutureTradeCancellationMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Strategy Trade Cancellation Message: 62 bytes                           *)
(***************************************************************************)

StrategyTradeCancellationMessage ==
    [ exchangeId             : Sample(1),
      symbol                 : Sample(30),
      volume                 : Sample(8),
      tradePriceSign         : Sample(1),
      tradePriceFractionPair : Sample(8),
      tradeNumber            : Sample(8),
      auctionId              : Sample(6) ]

EncodeStrategyTradeCancellationMessage(message) ==
    message.exchangeId
        \o message.symbol
        \o message.volume
        \o message.tradePriceSign
        \o message.tradePriceFractionPair
        \o message.tradeNumber
        \o message.auctionId

DecodeStrategyTradeCancellationMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET symbol == ReadBytes(exchangeId.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET volume == ReadBytes(symbol.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceSign == ReadBytes(volume.rest, 1) IN IF ~tradePriceSign.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(tradePriceSign.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(tradePriceFractionPair.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET auctionId == ReadBytes(tradeNumber.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         symbol                 |-> symbol.value,
         volume                 |-> volume.value,
         tradePriceSign         |-> tradePriceSign.value,
         tradePriceFractionPair |-> tradePriceFractionPair.value,
         tradeNumber            |-> tradeNumber.value,
         auctionId              |-> auctionId.value ], auctionId.rest)

ZeroStrategyTradeCancellationMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      symbol                 |-> [i \in 1 .. 30 |-> 0],
      volume                 |-> [i \in 1 .. 8 |-> 0],
      tradePriceSign         |-> [i \in 1 .. 1 |-> 0],
      tradePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      tradeNumber            |-> [i \in 1 .. 8 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0] ]

(* Strategy Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyTradeCancellationMessage ==
    { ZeroStrategyTradeCancellationMessage }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }
        \cup { [ZeroStrategyTradeCancellationMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol6 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol6(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol6(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol6 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol6 ==
    { ZeroOptionSymbol6 }
        \cup { [ZeroOptionSymbol6 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol6 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Instrument Keys Message: 146 bytes                               *)
(***************************************************************************)

OptionInstrumentKeysMessage ==
    [ exchangeId                                  : Sample(1),
      optionSymbol                                : OptionSymbol6,
      strikePriceCurrency                         : Sample(3),
      maximumNumberOfContractsPerOrder            : Sample(6),
      minimumNumberOfContractsPerOrder            : Sample(6),
      maximumThresholdPriceFractionPair           : Sample(8),
      minimumThresholdPriceInstrumentFractionPair : Sample(8),
      tickIncrement                               : Sample(8),
      optionType                                  : Sample(1),
      marketFlowIndicator                         : Sample(2),
      groupInstrument                             : Sample(2),
      instrument                                  : Sample(4),
      instrumentExternalCode                      : Sample(30),
      optionMarker                                : Sample(2),
      underlyingSymbolRoot                        : Sample(12),
      contractSize                                : Sample(8),
      tickValueFractionPair                       : Sample(8),
      currency                                    : Sample(3),
      deliveryType                                : Sample(1),
      lastTradingDatetime                         : Sample(14) ]

EncodeOptionInstrumentKeysMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol6(message.optionSymbol)
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceFractionPair
        \o message.minimumThresholdPriceInstrumentFractionPair
        \o message.tickIncrement
        \o message.optionType
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.optionMarker
        \o message.underlyingSymbolRoot
        \o message.contractSize
        \o message.tickValueFractionPair
        \o message.currency
        \o message.deliveryType
        \o message.lastTradingDatetime

DecodeOptionInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol6(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(optionSymbol.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionPair == ReadBytes(minimumNumberOfContractsPerOrder.rest, 8) IN IF ~maximumThresholdPriceFractionPair.ok THEN Fail ELSE
    LET minimumThresholdPriceInstrumentFractionPair == ReadBytes(maximumThresholdPriceFractionPair.rest, 8) IN IF ~minimumThresholdPriceInstrumentFractionPair.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceInstrumentFractionPair.rest, 8) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET optionType == ReadBytes(tickIncrement.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(optionType.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET optionMarker == ReadBytes(instrumentExternalCode.rest, 2) IN IF ~optionMarker.ok THEN Fail ELSE
    LET underlyingSymbolRoot == ReadBytes(optionMarker.rest, 12) IN IF ~underlyingSymbolRoot.ok THEN Fail ELSE
    LET contractSize == ReadBytes(underlyingSymbolRoot.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValueFractionPair == ReadBytes(contractSize.rest, 8) IN IF ~tickValueFractionPair.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionPair.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(currency.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET lastTradingDatetime == ReadBytes(deliveryType.rest, 14) IN IF ~lastTradingDatetime.ok THEN Fail ELSE
    Ok([ exchangeId                                  |-> exchangeId.value,
         optionSymbol                                |-> optionSymbol.value,
         strikePriceCurrency                         |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder            |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder            |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceFractionPair           |-> maximumThresholdPriceFractionPair.value,
         minimumThresholdPriceInstrumentFractionPair |-> minimumThresholdPriceInstrumentFractionPair.value,
         tickIncrement                               |-> tickIncrement.value,
         optionType                                  |-> optionType.value,
         marketFlowIndicator                         |-> marketFlowIndicator.value,
         groupInstrument                             |-> groupInstrument.value,
         instrument                                  |-> instrument.value,
         instrumentExternalCode                      |-> instrumentExternalCode.value,
         optionMarker                                |-> optionMarker.value,
         underlyingSymbolRoot                        |-> underlyingSymbolRoot.value,
         contractSize                                |-> contractSize.value,
         tickValueFractionPair                       |-> tickValueFractionPair.value,
         currency                                    |-> currency.value,
         deliveryType                                |-> deliveryType.value,
         lastTradingDatetime                         |-> lastTradingDatetime.value ], lastTradingDatetime.rest)

ZeroOptionInstrumentKeysMessage ==
    [ exchangeId                                  |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                                |-> ZeroOptionSymbol6,
      strikePriceCurrency                         |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder            |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder            |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionPair           |-> [i \in 1 .. 8 |-> 0],
      minimumThresholdPriceInstrumentFractionPair |-> [i \in 1 .. 8 |-> 0],
      tickIncrement                               |-> [i \in 1 .. 8 |-> 0],
      optionType                                  |-> [i \in 1 .. 1 |-> 0],
      marketFlowIndicator                         |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                             |-> [i \in 1 .. 2 |-> 0],
      instrument                                  |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                      |-> [i \in 1 .. 30 |-> 0],
      optionMarker                                |-> [i \in 1 .. 2 |-> 0],
      underlyingSymbolRoot                        |-> [i \in 1 .. 12 |-> 0],
      contractSize                                |-> [i \in 1 .. 8 |-> 0],
      tickValueFractionPair                       |-> [i \in 1 .. 8 |-> 0],
      currency                                    |-> [i \in 1 .. 3 |-> 0],
      deliveryType                                |-> [i \in 1 .. 1 |-> 0],
      lastTradingDatetime                         |-> [i \in 1 .. 14 |-> 0] ]

(* Option Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionInstrumentKeysMessage ==
    { ZeroOptionInstrumentKeysMessage }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol6 }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.minimumThresholdPriceInstrumentFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.optionMarker = one] : one \in Sample(2) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.underlyingSymbolRoot = one] : one \in Sample(12) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.tickValueFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInstrumentKeysMessage EXCEPT !.lastTradingDatetime = one] : one \in Sample(14) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol7 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol7(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol7(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol7 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol7 ==
    { ZeroFutureOptionSymbol7 }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol7 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Instrument Keys Message: 147 bytes                       *)
(***************************************************************************)

FutureOptionsInstrumentKeysMessage ==
    [ exchangeId                                  : Sample(1),
      futureOptionSymbol                          : FutureOptionSymbol7,
      expiryDate                                  : Sample(6),
      strikePriceCurrency                         : Sample(3),
      maximumNumberOfContractsPerOrder            : Sample(6),
      minimumNumberOfContractsPerOrder            : Sample(6),
      maximumThresholdPriceFractionPair           : Sample(8),
      minimumThresholdPriceInstrumentFractionPair : Sample(8),
      tickIncrement                               : Sample(8),
      marketFlowIndicator                         : Sample(2),
      groupInstrument                             : Sample(2),
      instrument                                  : Sample(4),
      instrumentExternalCode                      : Sample(30),
      contractSize                                : Sample(8),
      tickValueFractionPair                       : Sample(8),
      currency                                    : Sample(3),
      deliveryType                                : Sample(1),
      underlyingRootSymbol                        : Sample(6),
      underlyingSymbolMonth                       : Sample(1),
      underlyingSymbolYear                        : Sample(2),
      lastTradingDatetime                         : Sample(14) ]

EncodeFutureOptionsInstrumentKeysMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol7(message.futureOptionSymbol)
        \o message.expiryDate
        \o message.strikePriceCurrency
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceFractionPair
        \o message.minimumThresholdPriceInstrumentFractionPair
        \o message.tickIncrement
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.contractSize
        \o message.tickValueFractionPair
        \o message.currency
        \o message.deliveryType
        \o message.underlyingRootSymbol
        \o message.underlyingSymbolMonth
        \o message.underlyingSymbolYear
        \o message.lastTradingDatetime

DecodeFutureOptionsInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol7(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(futureOptionSymbol.rest, 6) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(expiryDate.rest, 3) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(strikePriceCurrency.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionPair == ReadBytes(minimumNumberOfContractsPerOrder.rest, 8) IN IF ~maximumThresholdPriceFractionPair.ok THEN Fail ELSE
    LET minimumThresholdPriceInstrumentFractionPair == ReadBytes(maximumThresholdPriceFractionPair.rest, 8) IN IF ~minimumThresholdPriceInstrumentFractionPair.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceInstrumentFractionPair.rest, 8) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrement.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET contractSize == ReadBytes(instrumentExternalCode.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValueFractionPair == ReadBytes(contractSize.rest, 8) IN IF ~tickValueFractionPair.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionPair.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(currency.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET underlyingRootSymbol == ReadBytes(deliveryType.rest, 6) IN IF ~underlyingRootSymbol.ok THEN Fail ELSE
    LET underlyingSymbolMonth == ReadBytes(underlyingRootSymbol.rest, 1) IN IF ~underlyingSymbolMonth.ok THEN Fail ELSE
    LET underlyingSymbolYear == ReadBytes(underlyingSymbolMonth.rest, 2) IN IF ~underlyingSymbolYear.ok THEN Fail ELSE
    LET lastTradingDatetime == ReadBytes(underlyingSymbolYear.rest, 14) IN IF ~lastTradingDatetime.ok THEN Fail ELSE
    Ok([ exchangeId                                  |-> exchangeId.value,
         futureOptionSymbol                          |-> futureOptionSymbol.value,
         expiryDate                                  |-> expiryDate.value,
         strikePriceCurrency                         |-> strikePriceCurrency.value,
         maximumNumberOfContractsPerOrder            |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder            |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceFractionPair           |-> maximumThresholdPriceFractionPair.value,
         minimumThresholdPriceInstrumentFractionPair |-> minimumThresholdPriceInstrumentFractionPair.value,
         tickIncrement                               |-> tickIncrement.value,
         marketFlowIndicator                         |-> marketFlowIndicator.value,
         groupInstrument                             |-> groupInstrument.value,
         instrument                                  |-> instrument.value,
         instrumentExternalCode                      |-> instrumentExternalCode.value,
         contractSize                                |-> contractSize.value,
         tickValueFractionPair                       |-> tickValueFractionPair.value,
         currency                                    |-> currency.value,
         deliveryType                                |-> deliveryType.value,
         underlyingRootSymbol                        |-> underlyingRootSymbol.value,
         underlyingSymbolMonth                       |-> underlyingSymbolMonth.value,
         underlyingSymbolYear                        |-> underlyingSymbolYear.value,
         lastTradingDatetime                         |-> lastTradingDatetime.value ], lastTradingDatetime.rest)

ZeroFutureOptionsInstrumentKeysMessage ==
    [ exchangeId                                  |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol                          |-> ZeroFutureOptionSymbol7,
      expiryDate                                  |-> [i \in 1 .. 6 |-> 0],
      strikePriceCurrency                         |-> [i \in 1 .. 3 |-> 0],
      maximumNumberOfContractsPerOrder            |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder            |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionPair           |-> [i \in 1 .. 8 |-> 0],
      minimumThresholdPriceInstrumentFractionPair |-> [i \in 1 .. 8 |-> 0],
      tickIncrement                               |-> [i \in 1 .. 8 |-> 0],
      marketFlowIndicator                         |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                             |-> [i \in 1 .. 2 |-> 0],
      instrument                                  |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                      |-> [i \in 1 .. 30 |-> 0],
      contractSize                                |-> [i \in 1 .. 8 |-> 0],
      tickValueFractionPair                       |-> [i \in 1 .. 8 |-> 0],
      currency                                    |-> [i \in 1 .. 3 |-> 0],
      deliveryType                                |-> [i \in 1 .. 1 |-> 0],
      underlyingRootSymbol                        |-> [i \in 1 .. 6 |-> 0],
      underlyingSymbolMonth                       |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbolYear                        |-> [i \in 1 .. 2 |-> 0],
      lastTradingDatetime                         |-> [i \in 1 .. 14 |-> 0] ]

(* Future Options Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsInstrumentKeysMessage ==
    { ZeroFutureOptionsInstrumentKeysMessage }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol7 }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.expiryDate = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.strikePriceCurrency = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.minimumThresholdPriceInstrumentFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.tickValueFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.underlyingRootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.underlyingSymbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.underlyingSymbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionsInstrumentKeysMessage EXCEPT !.lastTradingDatetime = one] : one \in Sample(14) }

(***************************************************************************)
(* Underlying Instrument Keys Message: 39 bytes                            *)
(***************************************************************************)

UnderlyingInstrumentKeysMessage ==
    [ exchangeId             : Sample(1),
      groupInstrument        : Sample(2),
      instrument             : Sample(4),
      instrumentExternalCode : Sample(30),
      marketFlowIndicator    : Sample(2) ]

EncodeUnderlyingInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.marketFlowIndicator

DecodeUnderlyingInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(instrumentExternalCode.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         groupInstrument        |-> groupInstrument.value,
         instrument             |-> instrument.value,
         instrumentExternalCode |-> instrumentExternalCode.value,
         marketFlowIndicator    |-> marketFlowIndicator.value ], marketFlowIndicator.rest)

ZeroUnderlyingInstrumentKeysMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      groupInstrument        |-> [i \in 1 .. 2 |-> 0],
      instrument             |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode |-> [i \in 1 .. 30 |-> 0],
      marketFlowIndicator    |-> [i \in 1 .. 2 |-> 0] ]

(* Underlying Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingInstrumentKeysMessage ==
    { ZeroUnderlyingInstrumentKeysMessage }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroUnderlyingInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct7 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct7(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct7(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct7 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct7 ==
    { ZeroFutureProduct7 }
        \cup { [ZeroFutureProduct7 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct7 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct7 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct7 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Associated Product: 11 bytes                                            *)
(***************************************************************************)

AssociatedProduct ==
    [ root        : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeAssociatedProduct(message) ==
    message.root
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeAssociatedProduct(bytes) ==
    LET root == ReadBytes(bytes, 6) IN IF ~root.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(root.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ root        |-> root.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroAssociatedProduct ==
    [ root        |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Associated Product at zero, then each field in turn at the values it is checked at *)
CheckedAssociatedProduct ==
    { ZeroAssociatedProduct }
        \cup { [ZeroAssociatedProduct EXCEPT !.root = one] : one \in Sample(6) }
        \cup { [ZeroAssociatedProduct EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroAssociatedProduct EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroAssociatedProduct EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Instrument Keys Message: 149 bytes                              *)
(***************************************************************************)

FuturesInstrumentKeysMessage ==
    [ exchangeId                               : Sample(1),
      futureProduct                            : FutureProduct7,
      expiryDate                               : Sample(6),
      maximumNumberOfContractsPerOrder         : Sample(6),
      minimumNumberOfContractsPerOrder         : Sample(6),
      maximumThresholdPriceFuturesFractionPair : Sample(8),
      minimumThresholdPriceFuturesFractionPair : Sample(8),
      tickIncrement                            : Sample(8),
      marketFlowIndicator                      : Sample(2),
      groupInstrument                          : Sample(2),
      instrument                               : Sample(4),
      instrumentExternalCode                   : Sample(30),
      contractSize                             : Sample(8),
      tickValueFractionPair                    : Sample(8),
      currency                                 : Sample(3),
      underlyingSymbol                         : Sample(12),
      deliveryType                             : Sample(1),
      associatedProduct                        : AssociatedProduct,
      lastTradingDatetime                      : Sample(14) ]

EncodeFuturesInstrumentKeysMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct7(message.futureProduct)
        \o message.expiryDate
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceFuturesFractionPair
        \o message.minimumThresholdPriceFuturesFractionPair
        \o message.tickIncrement
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.contractSize
        \o message.tickValueFractionPair
        \o message.currency
        \o message.underlyingSymbol
        \o message.deliveryType
        \o EncodeAssociatedProduct(message.associatedProduct)
        \o message.lastTradingDatetime

DecodeFuturesInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct7(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(futureProduct.rest, 6) IN IF ~expiryDate.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(expiryDate.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceFuturesFractionPair == ReadBytes(minimumNumberOfContractsPerOrder.rest, 8) IN IF ~maximumThresholdPriceFuturesFractionPair.ok THEN Fail ELSE
    LET minimumThresholdPriceFuturesFractionPair == ReadBytes(maximumThresholdPriceFuturesFractionPair.rest, 8) IN IF ~minimumThresholdPriceFuturesFractionPair.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceFuturesFractionPair.rest, 8) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrement.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET contractSize == ReadBytes(instrumentExternalCode.rest, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET tickValueFractionPair == ReadBytes(contractSize.rest, 8) IN IF ~tickValueFractionPair.ok THEN Fail ELSE
    LET currency == ReadBytes(tickValueFractionPair.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(currency.rest, 12) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET deliveryType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~deliveryType.ok THEN Fail ELSE
    LET associatedProduct == DecodeAssociatedProduct(deliveryType.rest) IN IF ~associatedProduct.ok THEN Fail ELSE
    LET lastTradingDatetime == ReadBytes(associatedProduct.rest, 14) IN IF ~lastTradingDatetime.ok THEN Fail ELSE
    Ok([ exchangeId                               |-> exchangeId.value,
         futureProduct                            |-> futureProduct.value,
         expiryDate                               |-> expiryDate.value,
         maximumNumberOfContractsPerOrder         |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder         |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceFuturesFractionPair |-> maximumThresholdPriceFuturesFractionPair.value,
         minimumThresholdPriceFuturesFractionPair |-> minimumThresholdPriceFuturesFractionPair.value,
         tickIncrement                            |-> tickIncrement.value,
         marketFlowIndicator                      |-> marketFlowIndicator.value,
         groupInstrument                          |-> groupInstrument.value,
         instrument                               |-> instrument.value,
         instrumentExternalCode                   |-> instrumentExternalCode.value,
         contractSize                             |-> contractSize.value,
         tickValueFractionPair                    |-> tickValueFractionPair.value,
         currency                                 |-> currency.value,
         underlyingSymbol                         |-> underlyingSymbol.value,
         deliveryType                             |-> deliveryType.value,
         associatedProduct                        |-> associatedProduct.value,
         lastTradingDatetime                      |-> lastTradingDatetime.value ], lastTradingDatetime.rest)

ZeroFuturesInstrumentKeysMessage ==
    [ exchangeId                               |-> [i \in 1 .. 1 |-> 0],
      futureProduct                            |-> ZeroFutureProduct7,
      expiryDate                               |-> [i \in 1 .. 6 |-> 0],
      maximumNumberOfContractsPerOrder         |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder         |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFuturesFractionPair |-> [i \in 1 .. 8 |-> 0],
      minimumThresholdPriceFuturesFractionPair |-> [i \in 1 .. 8 |-> 0],
      tickIncrement                            |-> [i \in 1 .. 8 |-> 0],
      marketFlowIndicator                      |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                          |-> [i \in 1 .. 2 |-> 0],
      instrument                               |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                   |-> [i \in 1 .. 30 |-> 0],
      contractSize                             |-> [i \in 1 .. 8 |-> 0],
      tickValueFractionPair                    |-> [i \in 1 .. 8 |-> 0],
      currency                                 |-> [i \in 1 .. 3 |-> 0],
      underlyingSymbol                         |-> [i \in 1 .. 12 |-> 0],
      deliveryType                             |-> [i \in 1 .. 1 |-> 0],
      associatedProduct                        |-> ZeroAssociatedProduct,
      lastTradingDatetime                      |-> [i \in 1 .. 14 |-> 0] ]

(* Futures Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesInstrumentKeysMessage ==
    { ZeroFuturesInstrumentKeysMessage }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct7 }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.expiryDate = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFuturesFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.minimumThresholdPriceFuturesFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.tickValueFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(12) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.deliveryType = one] : one \in Sample(1) }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.associatedProduct = one] : one \in CheckedAssociatedProduct }
        \cup { [ZeroFuturesInstrumentKeysMessage EXCEPT !.lastTradingDatetime = one] : one \in Sample(14) }

(***************************************************************************)
(* Strategy Instrument Leg: 19 bytes                                       *)
(***************************************************************************)

StrategyInstrumentLeg ==
    [ legGroupInstrument          : Sample(2),
      legInstrument               : Sample(4),
      legRatioOrDeltaFractionPair : Sample(5),
      legPriceFractionPair        : Sample(8) ]

EncodeStrategyInstrumentLeg(message) ==
    message.legGroupInstrument
        \o message.legInstrument
        \o message.legRatioOrDeltaFractionPair
        \o message.legPriceFractionPair

DecodeStrategyInstrumentLeg(bytes) ==
    LET legGroupInstrument == ReadBytes(bytes, 2) IN IF ~legGroupInstrument.ok THEN Fail ELSE
    LET legInstrument == ReadBytes(legGroupInstrument.rest, 4) IN IF ~legInstrument.ok THEN Fail ELSE
    LET legRatioOrDeltaFractionPair == ReadBytes(legInstrument.rest, 5) IN IF ~legRatioOrDeltaFractionPair.ok THEN Fail ELSE
    LET legPriceFractionPair == ReadBytes(legRatioOrDeltaFractionPair.rest, 8) IN IF ~legPriceFractionPair.ok THEN Fail ELSE
    Ok([ legGroupInstrument          |-> legGroupInstrument.value,
         legInstrument               |-> legInstrument.value,
         legRatioOrDeltaFractionPair |-> legRatioOrDeltaFractionPair.value,
         legPriceFractionPair        |-> legPriceFractionPair.value ], legPriceFractionPair.rest)

ZeroStrategyInstrumentLeg ==
    [ legGroupInstrument          |-> [i \in 1 .. 2 |-> 0],
      legInstrument               |-> [i \in 1 .. 4 |-> 0],
      legRatioOrDeltaFractionPair |-> [i \in 1 .. 5 |-> 0],
      legPriceFractionPair        |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Instrument Leg at zero, then each field in turn at the values it is checked at *)
CheckedStrategyInstrumentLeg ==
    { ZeroStrategyInstrumentLeg }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legGroupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legInstrument = one] : one \in Sample(4) }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legRatioOrDeltaFractionPair = one] : one \in Sample(5) }
        \cup { [ZeroStrategyInstrumentLeg EXCEPT !.legPriceFractionPair = one] : one \in Sample(8) }

(* A run of Strategy Instrument Leg, written one after another *)
RECURSIVE EncodeStrategyInstrumentLegList(_)
EncodeStrategyInstrumentLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyInstrumentLeg(Head(messages)) \o EncodeStrategyInstrumentLegList(Tail(messages))

(* As many Strategy Instrument Leg as the field that counts them says *)
RECURSIVE ReadStrategyInstrumentLegList(_, _)
ReadStrategyInstrumentLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyInstrumentLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyInstrumentLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Instrument Leg of each kind, for the lists that carry them *)
OneStrategyInstrumentLeg == { ZeroStrategyInstrumentLeg }

(***************************************************************************)
(* Strategy Instrument Keys Message                                        *)
(***************************************************************************)

StrategyInstrumentKeysMessage ==
    [ exchangeId                                : Sample(1),
      strategySymbol                            : Sample(30),
      expiryYear                                : Sample(2),
      expiryMonthStrategy                       : Sample(1),
      expiryDay                                 : Sample(2),
      maximumNumberOfContractsPerOrder          : Sample(6),
      minimumNumberOfContractsPerOrder          : Sample(6),
      maximumThresholdPriceFractionPair         : Sample(8),
      minimumThresholdPriceStrategyFractionPair : Sample(8),
      tickIncrement                             : Sample(8),
      marketFlowIndicator                       : Sample(2),
      groupInstrument                           : Sample(2),
      instrument                                : Sample(4),
      instrumentExternalCode                    : Sample(30),
      strategyAllowImplied                      : Sample(1),
      strategyCode                              : Sample(2),
      strategyType                              : Sample(1),
      lastTradingDatetime                       : Sample(14),
      variableLegsStrategyCode                  : Sample(2),
      strategyInstrumentLeg                     : SampleLists(OneStrategyInstrumentLeg) ]

EncodeStrategyInstrumentKeysMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.expiryYear
        \o message.expiryMonthStrategy
        \o message.expiryDay
        \o message.maximumNumberOfContractsPerOrder
        \o message.minimumNumberOfContractsPerOrder
        \o message.maximumThresholdPriceFractionPair
        \o message.minimumThresholdPriceStrategyFractionPair
        \o message.tickIncrement
        \o message.marketFlowIndicator
        \o message.groupInstrument
        \o message.instrument
        \o message.instrumentExternalCode
        \o message.strategyAllowImplied
        \o message.strategyCode
        \o message.strategyType
        \o message.lastTradingDatetime
        \o message.variableLegsStrategyCode
        \o EncodeDigits(Len(message.strategyInstrumentLeg), 2)
        \o EncodeStrategyInstrumentLegList(message.strategyInstrumentLeg)

DecodeStrategyInstrumentKeysMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strategySymbol.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryMonthStrategy == ReadBytes(expiryYear.rest, 1) IN IF ~expiryMonthStrategy.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryMonthStrategy.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET maximumNumberOfContractsPerOrder == ReadBytes(expiryDay.rest, 6) IN IF ~maximumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET minimumNumberOfContractsPerOrder == ReadBytes(maximumNumberOfContractsPerOrder.rest, 6) IN IF ~minimumNumberOfContractsPerOrder.ok THEN Fail ELSE
    LET maximumThresholdPriceFractionPair == ReadBytes(minimumNumberOfContractsPerOrder.rest, 8) IN IF ~maximumThresholdPriceFractionPair.ok THEN Fail ELSE
    LET minimumThresholdPriceStrategyFractionPair == ReadBytes(maximumThresholdPriceFractionPair.rest, 8) IN IF ~minimumThresholdPriceStrategyFractionPair.ok THEN Fail ELSE
    LET tickIncrement == ReadBytes(minimumThresholdPriceStrategyFractionPair.rest, 8) IN IF ~tickIncrement.ok THEN Fail ELSE
    LET marketFlowIndicator == ReadBytes(tickIncrement.rest, 2) IN IF ~marketFlowIndicator.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(marketFlowIndicator.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET instrument == ReadBytes(groupInstrument.rest, 4) IN IF ~instrument.ok THEN Fail ELSE
    LET instrumentExternalCode == ReadBytes(instrument.rest, 30) IN IF ~instrumentExternalCode.ok THEN Fail ELSE
    LET strategyAllowImplied == ReadBytes(instrumentExternalCode.rest, 1) IN IF ~strategyAllowImplied.ok THEN Fail ELSE
    LET strategyCode == ReadBytes(strategyAllowImplied.rest, 2) IN IF ~strategyCode.ok THEN Fail ELSE
    LET strategyType == ReadBytes(strategyCode.rest, 1) IN IF ~strategyType.ok THEN Fail ELSE
    LET lastTradingDatetime == ReadBytes(strategyType.rest, 14) IN IF ~lastTradingDatetime.ok THEN Fail ELSE
    LET variableLegsStrategyCode == ReadBytes(lastTradingDatetime.rest, 2) IN IF ~variableLegsStrategyCode.ok THEN Fail ELSE
    LET numberOfLegs == ReadDigits(variableLegsStrategyCode.rest, 2) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET strategyInstrumentLeg == ReadStrategyInstrumentLegList(numberOfLegs.rest, numberOfLegs.value) IN IF ~strategyInstrumentLeg.ok THEN Fail ELSE
    Ok([ exchangeId                                |-> exchangeId.value,
         strategySymbol                            |-> strategySymbol.value,
         expiryYear                                |-> expiryYear.value,
         expiryMonthStrategy                       |-> expiryMonthStrategy.value,
         expiryDay                                 |-> expiryDay.value,
         maximumNumberOfContractsPerOrder          |-> maximumNumberOfContractsPerOrder.value,
         minimumNumberOfContractsPerOrder          |-> minimumNumberOfContractsPerOrder.value,
         maximumThresholdPriceFractionPair         |-> maximumThresholdPriceFractionPair.value,
         minimumThresholdPriceStrategyFractionPair |-> minimumThresholdPriceStrategyFractionPair.value,
         tickIncrement                             |-> tickIncrement.value,
         marketFlowIndicator                       |-> marketFlowIndicator.value,
         groupInstrument                           |-> groupInstrument.value,
         instrument                                |-> instrument.value,
         instrumentExternalCode                    |-> instrumentExternalCode.value,
         strategyAllowImplied                      |-> strategyAllowImplied.value,
         strategyCode                              |-> strategyCode.value,
         strategyType                              |-> strategyType.value,
         lastTradingDatetime                       |-> lastTradingDatetime.value,
         variableLegsStrategyCode                  |-> variableLegsStrategyCode.value,
         strategyInstrumentLeg                     |-> strategyInstrumentLeg.value ], strategyInstrumentLeg.rest)

ZeroStrategyInstrumentKeysMessage ==
    [ exchangeId                                |-> [i \in 1 .. 1 |-> 0],
      strategySymbol                            |-> [i \in 1 .. 30 |-> 0],
      expiryYear                                |-> [i \in 1 .. 2 |-> 0],
      expiryMonthStrategy                       |-> [i \in 1 .. 1 |-> 0],
      expiryDay                                 |-> [i \in 1 .. 2 |-> 0],
      maximumNumberOfContractsPerOrder          |-> [i \in 1 .. 6 |-> 0],
      minimumNumberOfContractsPerOrder          |-> [i \in 1 .. 6 |-> 0],
      maximumThresholdPriceFractionPair         |-> [i \in 1 .. 8 |-> 0],
      minimumThresholdPriceStrategyFractionPair |-> [i \in 1 .. 8 |-> 0],
      tickIncrement                             |-> [i \in 1 .. 8 |-> 0],
      marketFlowIndicator                       |-> [i \in 1 .. 2 |-> 0],
      groupInstrument                           |-> [i \in 1 .. 2 |-> 0],
      instrument                                |-> [i \in 1 .. 4 |-> 0],
      instrumentExternalCode                    |-> [i \in 1 .. 30 |-> 0],
      strategyAllowImplied                      |-> [i \in 1 .. 1 |-> 0],
      strategyCode                              |-> [i \in 1 .. 2 |-> 0],
      strategyType                              |-> [i \in 1 .. 1 |-> 0],
      lastTradingDatetime                       |-> [i \in 1 .. 14 |-> 0],
      variableLegsStrategyCode                  |-> [i \in 1 .. 2 |-> 0],
      strategyInstrumentLeg                     |-> << >> ]

(* Strategy Instrument Keys Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyInstrumentKeysMessage ==
    { ZeroStrategyInstrumentKeysMessage }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryMonthStrategy = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumNumberOfContractsPerOrder = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.maximumThresholdPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.minimumThresholdPriceStrategyFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.tickIncrement = one] : one \in Sample(8) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.marketFlowIndicator = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.instrument = one] : one \in Sample(4) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.instrumentExternalCode = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyAllowImplied = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyCode = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.lastTradingDatetime = one] : one \in Sample(14) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.variableLegsStrategyCode = one] : one \in Sample(2) }
        \cup { [ZeroStrategyInstrumentKeysMessage EXCEPT !.strategyInstrumentLeg = one] : one \in SampleLists(OneStrategyInstrumentLeg) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol7 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol7(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol7(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol7 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol7 ==
    { ZeroOptionSymbol7 }
        \cup { [ZeroOptionSymbol7 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol7 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Auction Beginning Message: 83 bytes                              *)
(***************************************************************************)

OptionAuctionBeginningMessage ==
    [ exchangeId                    : Sample(1),
      optionSymbol                  : OptionSymbol7,
      auctionId                     : Sample(6),
      initialOrderSide              : Sample(1),
      initialOrderQuantity          : Sample(8),
      initialOrderPriceFractionPair : Sample(8),
      auctionExpiryTimestamp        : Sample(20),
      auctionDuration               : Sample(12),
      initialQuantityAssured        : Sample(8) ]

EncodeOptionAuctionBeginningMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol7(message.optionSymbol)
        \o message.auctionId
        \o message.initialOrderSide
        \o message.initialOrderQuantity
        \o message.initialOrderPriceFractionPair
        \o message.auctionExpiryTimestamp
        \o message.auctionDuration
        \o message.initialQuantityAssured

DecodeOptionAuctionBeginningMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol7(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(optionSymbol.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET initialOrderSide == ReadBytes(auctionId.rest, 1) IN IF ~initialOrderSide.ok THEN Fail ELSE
    LET initialOrderQuantity == ReadBytes(initialOrderSide.rest, 8) IN IF ~initialOrderQuantity.ok THEN Fail ELSE
    LET initialOrderPriceFractionPair == ReadBytes(initialOrderQuantity.rest, 8) IN IF ~initialOrderPriceFractionPair.ok THEN Fail ELSE
    LET auctionExpiryTimestamp == ReadBytes(initialOrderPriceFractionPair.rest, 20) IN IF ~auctionExpiryTimestamp.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionExpiryTimestamp.rest, 12) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET initialQuantityAssured == ReadBytes(auctionDuration.rest, 8) IN IF ~initialQuantityAssured.ok THEN Fail ELSE
    Ok([ exchangeId                    |-> exchangeId.value,
         optionSymbol                  |-> optionSymbol.value,
         auctionId                     |-> auctionId.value,
         initialOrderSide              |-> initialOrderSide.value,
         initialOrderQuantity          |-> initialOrderQuantity.value,
         initialOrderPriceFractionPair |-> initialOrderPriceFractionPair.value,
         auctionExpiryTimestamp        |-> auctionExpiryTimestamp.value,
         auctionDuration               |-> auctionDuration.value,
         initialQuantityAssured        |-> initialQuantityAssured.value ], initialQuantityAssured.rest)

ZeroOptionAuctionBeginningMessage ==
    [ exchangeId                    |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                  |-> ZeroOptionSymbol7,
      auctionId                     |-> [i \in 1 .. 6 |-> 0],
      initialOrderSide              |-> [i \in 1 .. 1 |-> 0],
      initialOrderQuantity          |-> [i \in 1 .. 8 |-> 0],
      initialOrderPriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      auctionExpiryTimestamp        |-> [i \in 1 .. 20 |-> 0],
      auctionDuration               |-> [i \in 1 .. 12 |-> 0],
      initialQuantityAssured        |-> [i \in 1 .. 8 |-> 0] ]

(* Option Auction Beginning Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionAuctionBeginningMessage ==
    { ZeroOptionAuctionBeginningMessage }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol7 }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.initialOrderSide = one] : one \in Sample(1) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.initialOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.initialOrderPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.auctionExpiryTimestamp = one] : one \in Sample(20) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.auctionDuration = one] : one \in Sample(12) }
        \cup { [ZeroOptionAuctionBeginningMessage EXCEPT !.initialQuantityAssured = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Auction Beginning Message: 94 bytes                            *)
(***************************************************************************)

StrategyAuctionBeginningMessage ==
    [ exchangeId                    : Sample(1),
      strategySymbol                : Sample(30),
      auctionId                     : Sample(6),
      initialOrderSide              : Sample(1),
      initialOrderQuantity          : Sample(8),
      initialOrderPriceFractionPair : Sample(8),
      auctionExpiryTimestamp        : Sample(20),
      auctionDuration               : Sample(12),
      initialQuantityAssured        : Sample(8) ]

EncodeStrategyAuctionBeginningMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.auctionId
        \o message.initialOrderSide
        \o message.initialOrderQuantity
        \o message.initialOrderPriceFractionPair
        \o message.auctionExpiryTimestamp
        \o message.auctionDuration
        \o message.initialQuantityAssured

DecodeStrategyAuctionBeginningMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategySymbol.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET initialOrderSide == ReadBytes(auctionId.rest, 1) IN IF ~initialOrderSide.ok THEN Fail ELSE
    LET initialOrderQuantity == ReadBytes(initialOrderSide.rest, 8) IN IF ~initialOrderQuantity.ok THEN Fail ELSE
    LET initialOrderPriceFractionPair == ReadBytes(initialOrderQuantity.rest, 8) IN IF ~initialOrderPriceFractionPair.ok THEN Fail ELSE
    LET auctionExpiryTimestamp == ReadBytes(initialOrderPriceFractionPair.rest, 20) IN IF ~auctionExpiryTimestamp.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionExpiryTimestamp.rest, 12) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET initialQuantityAssured == ReadBytes(auctionDuration.rest, 8) IN IF ~initialQuantityAssured.ok THEN Fail ELSE
    Ok([ exchangeId                    |-> exchangeId.value,
         strategySymbol                |-> strategySymbol.value,
         auctionId                     |-> auctionId.value,
         initialOrderSide              |-> initialOrderSide.value,
         initialOrderQuantity          |-> initialOrderQuantity.value,
         initialOrderPriceFractionPair |-> initialOrderPriceFractionPair.value,
         auctionExpiryTimestamp        |-> auctionExpiryTimestamp.value,
         auctionDuration               |-> auctionDuration.value,
         initialQuantityAssured        |-> initialQuantityAssured.value ], initialQuantityAssured.rest)

ZeroStrategyAuctionBeginningMessage ==
    [ exchangeId                    |-> [i \in 1 .. 1 |-> 0],
      strategySymbol                |-> [i \in 1 .. 30 |-> 0],
      auctionId                     |-> [i \in 1 .. 6 |-> 0],
      initialOrderSide              |-> [i \in 1 .. 1 |-> 0],
      initialOrderQuantity          |-> [i \in 1 .. 8 |-> 0],
      initialOrderPriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      auctionExpiryTimestamp        |-> [i \in 1 .. 20 |-> 0],
      auctionDuration               |-> [i \in 1 .. 12 |-> 0],
      initialQuantityAssured        |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Auction Beginning Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyAuctionBeginningMessage ==
    { ZeroStrategyAuctionBeginningMessage }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.initialOrderSide = one] : one \in Sample(1) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.initialOrderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.initialOrderPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.auctionExpiryTimestamp = one] : one \in Sample(20) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.auctionDuration = one] : one \in Sample(12) }
        \cup { [ZeroStrategyAuctionBeginningMessage EXCEPT !.initialQuantityAssured = one] : one \in Sample(8) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol8 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol8(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol8(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol8 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol8 ==
    { ZeroOptionSymbol8 }
        \cup { [ZeroOptionSymbol8 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol8 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Summary Message: 128 bytes                                       *)
(***************************************************************************)

OptionSummaryMessage ==
    [ exchangeId                                : Sample(1),
      optionSymbol                              : OptionSymbol8,
      bidPriceSummaryFractionPair               : Sample(8),
      bidSize                                   : Sample(5),
      askPriceSummaryFractionPair               : Sample(8),
      askSize                                   : Sample(5),
      lastPriceFractionPair                     : Sample(8),
      openInterest                              : Sample(7),
      openInterestDate                          : Sample(6),
      tick                                      : Sample(1),
      volume                                    : Sample(8),
      netChangeSign                             : Sample(1),
      netChangeOptionSummaryMessageFractionPair : Sample(8),
      openPriceFractionPair                     : Sample(8),
      highPriceFractionPair                     : Sample(8),
      lowPriceFractionPair                      : Sample(8),
      optionMarker                              : Sample(2),
      closingPriceFractionPair                  : Sample(8),
      previousClosingPriceFractionPair          : Sample(8),
      reason                                    : Sample(1) ]

EncodeOptionSummaryMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol8(message.optionSymbol)
        \o message.bidPriceSummaryFractionPair
        \o message.bidSize
        \o message.askPriceSummaryFractionPair
        \o message.askSize
        \o message.lastPriceFractionPair
        \o message.openInterest
        \o message.openInterestDate
        \o message.tick
        \o message.volume
        \o message.netChangeSign
        \o message.netChangeOptionSummaryMessageFractionPair
        \o message.openPriceFractionPair
        \o message.highPriceFractionPair
        \o message.lowPriceFractionPair
        \o message.optionMarker
        \o message.closingPriceFractionPair
        \o message.previousClosingPriceFractionPair
        \o message.reason

DecodeOptionSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol8(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET bidPriceSummaryFractionPair == ReadBytes(optionSymbol.rest, 8) IN IF ~bidPriceSummaryFractionPair.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceSummaryFractionPair.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummaryFractionPair == ReadBytes(bidSize.rest, 8) IN IF ~askPriceSummaryFractionPair.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceSummaryFractionPair.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceFractionPair == ReadBytes(askSize.rest, 8) IN IF ~lastPriceFractionPair.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastPriceFractionPair.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(openInterest.rest, 6) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET tick == ReadBytes(openInterestDate.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeOptionSummaryMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeOptionSummaryMessageFractionPair.ok THEN Fail ELSE
    LET openPriceFractionPair == ReadBytes(netChangeOptionSummaryMessageFractionPair.rest, 8) IN IF ~openPriceFractionPair.ok THEN Fail ELSE
    LET highPriceFractionPair == ReadBytes(openPriceFractionPair.rest, 8) IN IF ~highPriceFractionPair.ok THEN Fail ELSE
    LET lowPriceFractionPair == ReadBytes(highPriceFractionPair.rest, 8) IN IF ~lowPriceFractionPair.ok THEN Fail ELSE
    LET optionMarker == ReadBytes(lowPriceFractionPair.rest, 2) IN IF ~optionMarker.ok THEN Fail ELSE
    LET closingPriceFractionPair == ReadBytes(optionMarker.rest, 8) IN IF ~closingPriceFractionPair.ok THEN Fail ELSE
    LET previousClosingPriceFractionPair == ReadBytes(closingPriceFractionPair.rest, 8) IN IF ~previousClosingPriceFractionPair.ok THEN Fail ELSE
    LET reason == ReadBytes(previousClosingPriceFractionPair.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ exchangeId                                |-> exchangeId.value,
         optionSymbol                              |-> optionSymbol.value,
         bidPriceSummaryFractionPair               |-> bidPriceSummaryFractionPair.value,
         bidSize                                   |-> bidSize.value,
         askPriceSummaryFractionPair               |-> askPriceSummaryFractionPair.value,
         askSize                                   |-> askSize.value,
         lastPriceFractionPair                     |-> lastPriceFractionPair.value,
         openInterest                              |-> openInterest.value,
         openInterestDate                          |-> openInterestDate.value,
         tick                                      |-> tick.value,
         volume                                    |-> volume.value,
         netChangeSign                             |-> netChangeSign.value,
         netChangeOptionSummaryMessageFractionPair |-> netChangeOptionSummaryMessageFractionPair.value,
         openPriceFractionPair                     |-> openPriceFractionPair.value,
         highPriceFractionPair                     |-> highPriceFractionPair.value,
         lowPriceFractionPair                      |-> lowPriceFractionPair.value,
         optionMarker                              |-> optionMarker.value,
         closingPriceFractionPair                  |-> closingPriceFractionPair.value,
         previousClosingPriceFractionPair          |-> previousClosingPriceFractionPair.value,
         reason                                    |-> reason.value ], reason.rest)

ZeroOptionSummaryMessage ==
    [ exchangeId                                |-> [i \in 1 .. 1 |-> 0],
      optionSymbol                              |-> ZeroOptionSymbol8,
      bidPriceSummaryFractionPair               |-> [i \in 1 .. 8 |-> 0],
      bidSize                                   |-> [i \in 1 .. 5 |-> 0],
      askPriceSummaryFractionPair               |-> [i \in 1 .. 8 |-> 0],
      askSize                                   |-> [i \in 1 .. 5 |-> 0],
      lastPriceFractionPair                     |-> [i \in 1 .. 8 |-> 0],
      openInterest                              |-> [i \in 1 .. 7 |-> 0],
      openInterestDate                          |-> [i \in 1 .. 6 |-> 0],
      tick                                      |-> [i \in 1 .. 1 |-> 0],
      volume                                    |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                             |-> [i \in 1 .. 1 |-> 0],
      netChangeOptionSummaryMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      openPriceFractionPair                     |-> [i \in 1 .. 8 |-> 0],
      highPriceFractionPair                     |-> [i \in 1 .. 8 |-> 0],
      lowPriceFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      optionMarker                              |-> [i \in 1 .. 2 |-> 0],
      closingPriceFractionPair                  |-> [i \in 1 .. 8 |-> 0],
      previousClosingPriceFractionPair          |-> [i \in 1 .. 8 |-> 0],
      reason                                    |-> [i \in 1 .. 1 |-> 0] ]

(* Option Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionSummaryMessage ==
    { ZeroOptionSummaryMessage }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol8 }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lastPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openInterestDate = one] : one \in Sample(6) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.netChangeOptionSummaryMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.openPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.highPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.lowPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.optionMarker = one] : one \in Sample(2) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.closingPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.previousClosingPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Option Symbol: 20 bytes                                          *)
(***************************************************************************)

FutureOptionSymbol8 ==
    [ rootSymbol              : Sample(6),
      symbolMonth             : Sample(1),
      symbolYear              : Sample(2),
      expiryDay               : Sample(2),
      callPutCode             : Sample(1),
      strikePriceFractionPair : Sample(8) ]

EncodeFutureOptionSymbol8(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay
        \o message.callPutCode
        \o message.strikePriceFractionPair

DecodeFutureOptionSymbol8(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    LET callPutCode == ReadBytes(expiryDay.rest, 1) IN IF ~callPutCode.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(callPutCode.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         symbolMonth             |-> symbolMonth.value,
         symbolYear              |-> symbolYear.value,
         expiryDay               |-> expiryDay.value,
         callPutCode             |-> callPutCode.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value ], strikePriceFractionPair.rest)

ZeroFutureOptionSymbol8 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      symbolMonth             |-> [i \in 1 .. 1 |-> 0],
      symbolYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0],
      callPutCode             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Future Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionSymbol8 ==
    { ZeroFutureOptionSymbol8 }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.expiryDay = one] : one \in Sample(2) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.callPutCode = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionSymbol8 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Future Options Summary Message: 127 bytes                               *)
(***************************************************************************)

FutureOptionsSummaryMessage ==
    [ exchangeId                                       : Sample(1),
      futureOptionSymbol                               : FutureOptionSymbol8,
      bidPriceSummaryFractionPair                      : Sample(8),
      bidSize                                          : Sample(5),
      askPriceSummaryFractionPair                      : Sample(8),
      askSize                                          : Sample(5),
      lastPriceFractionPair                            : Sample(8),
      openInterest                                     : Sample(7),
      openInterestDate                                 : Sample(6),
      tick                                             : Sample(1),
      volume                                           : Sample(8),
      netChangeSign                                    : Sample(1),
      netChangeFutureOptionsSummaryMessageFractionPair : Sample(8),
      openingPriceFractionPair                         : Sample(8),
      highPriceFractionPair                            : Sample(8),
      lowPriceFractionPair                             : Sample(8),
      settlementPriceFractionPair                      : Sample(8),
      previousSettlementPriceFractionPair              : Sample(8),
      reason                                           : Sample(1) ]

EncodeFutureOptionsSummaryMessage(message) ==
    message.exchangeId
        \o EncodeFutureOptionSymbol8(message.futureOptionSymbol)
        \o message.bidPriceSummaryFractionPair
        \o message.bidSize
        \o message.askPriceSummaryFractionPair
        \o message.askSize
        \o message.lastPriceFractionPair
        \o message.openInterest
        \o message.openInterestDate
        \o message.tick
        \o message.volume
        \o message.netChangeSign
        \o message.netChangeFutureOptionsSummaryMessageFractionPair
        \o message.openingPriceFractionPair
        \o message.highPriceFractionPair
        \o message.lowPriceFractionPair
        \o message.settlementPriceFractionPair
        \o message.previousSettlementPriceFractionPair
        \o message.reason

DecodeFutureOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureOptionSymbol == DecodeFutureOptionSymbol8(exchangeId.rest) IN IF ~futureOptionSymbol.ok THEN Fail ELSE
    LET bidPriceSummaryFractionPair == ReadBytes(futureOptionSymbol.rest, 8) IN IF ~bidPriceSummaryFractionPair.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceSummaryFractionPair.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummaryFractionPair == ReadBytes(bidSize.rest, 8) IN IF ~askPriceSummaryFractionPair.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceSummaryFractionPair.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceFractionPair == ReadBytes(askSize.rest, 8) IN IF ~lastPriceFractionPair.ok THEN Fail ELSE
    LET openInterest == ReadBytes(lastPriceFractionPair.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(openInterest.rest, 6) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET tick == ReadBytes(openInterestDate.rest, 1) IN IF ~tick.ok THEN Fail ELSE
    LET volume == ReadBytes(tick.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(volume.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFutureOptionsSummaryMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFutureOptionsSummaryMessageFractionPair.ok THEN Fail ELSE
    LET openingPriceFractionPair == ReadBytes(netChangeFutureOptionsSummaryMessageFractionPair.rest, 8) IN IF ~openingPriceFractionPair.ok THEN Fail ELSE
    LET highPriceFractionPair == ReadBytes(openingPriceFractionPair.rest, 8) IN IF ~highPriceFractionPair.ok THEN Fail ELSE
    LET lowPriceFractionPair == ReadBytes(highPriceFractionPair.rest, 8) IN IF ~lowPriceFractionPair.ok THEN Fail ELSE
    LET settlementPriceFractionPair == ReadBytes(lowPriceFractionPair.rest, 8) IN IF ~settlementPriceFractionPair.ok THEN Fail ELSE
    LET previousSettlementPriceFractionPair == ReadBytes(settlementPriceFractionPair.rest, 8) IN IF ~previousSettlementPriceFractionPair.ok THEN Fail ELSE
    LET reason == ReadBytes(previousSettlementPriceFractionPair.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ exchangeId                                       |-> exchangeId.value,
         futureOptionSymbol                               |-> futureOptionSymbol.value,
         bidPriceSummaryFractionPair                      |-> bidPriceSummaryFractionPair.value,
         bidSize                                          |-> bidSize.value,
         askPriceSummaryFractionPair                      |-> askPriceSummaryFractionPair.value,
         askSize                                          |-> askSize.value,
         lastPriceFractionPair                            |-> lastPriceFractionPair.value,
         openInterest                                     |-> openInterest.value,
         openInterestDate                                 |-> openInterestDate.value,
         tick                                             |-> tick.value,
         volume                                           |-> volume.value,
         netChangeSign                                    |-> netChangeSign.value,
         netChangeFutureOptionsSummaryMessageFractionPair |-> netChangeFutureOptionsSummaryMessageFractionPair.value,
         openingPriceFractionPair                         |-> openingPriceFractionPair.value,
         highPriceFractionPair                            |-> highPriceFractionPair.value,
         lowPriceFractionPair                             |-> lowPriceFractionPair.value,
         settlementPriceFractionPair                      |-> settlementPriceFractionPair.value,
         previousSettlementPriceFractionPair              |-> previousSettlementPriceFractionPair.value,
         reason                                           |-> reason.value ], reason.rest)

ZeroFutureOptionsSummaryMessage ==
    [ exchangeId                                       |-> [i \in 1 .. 1 |-> 0],
      futureOptionSymbol                               |-> ZeroFutureOptionSymbol8,
      bidPriceSummaryFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      bidSize                                          |-> [i \in 1 .. 5 |-> 0],
      askPriceSummaryFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      askSize                                          |-> [i \in 1 .. 5 |-> 0],
      lastPriceFractionPair                            |-> [i \in 1 .. 8 |-> 0],
      openInterest                                     |-> [i \in 1 .. 7 |-> 0],
      openInterestDate                                 |-> [i \in 1 .. 6 |-> 0],
      tick                                             |-> [i \in 1 .. 1 |-> 0],
      volume                                           |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                                    |-> [i \in 1 .. 1 |-> 0],
      netChangeFutureOptionsSummaryMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      openingPriceFractionPair                         |-> [i \in 1 .. 8 |-> 0],
      highPriceFractionPair                            |-> [i \in 1 .. 8 |-> 0],
      lowPriceFractionPair                             |-> [i \in 1 .. 8 |-> 0],
      settlementPriceFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      previousSettlementPriceFractionPair              |-> [i \in 1 .. 8 |-> 0],
      reason                                           |-> [i \in 1 .. 1 |-> 0] ]

(* Future Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureOptionsSummaryMessage ==
    { ZeroFutureOptionsSummaryMessage }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.futureOptionSymbol = one] : one \in CheckedFutureOptionSymbol8 }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lastPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openInterestDate = one] : one \in Sample(6) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.tick = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.netChangeFutureOptionsSummaryMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.openingPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.highPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.lowPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.settlementPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.previousSettlementPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFutureOptionsSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct8 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct8(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct8(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct8 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct8 ==
    { ZeroFutureProduct8 }
        \cup { [ZeroFutureProduct8 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct8 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct8 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct8 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Summary Message: 125 bytes                                      *)
(***************************************************************************)

FuturesSummaryMessage ==
    [ exchangeId                                 : Sample(1),
      futureProduct                              : FutureProduct8,
      bidPriceSummaryFractionPair                : Sample(8),
      bidSize                                    : Sample(5),
      askPriceSummaryFractionPair                : Sample(8),
      askSize                                    : Sample(5),
      lastPriceFractionPair                      : Sample(8),
      openPriceFractionPair                      : Sample(8),
      highPriceFractionPair                      : Sample(8),
      lowPriceFractionPair                       : Sample(8),
      settlementPriceFractionPair                : Sample(8),
      netChangeSign                              : Sample(1),
      netChangeFuturesSummaryMessageFractionPair : Sample(8),
      volume                                     : Sample(8),
      previousSettlementFractionPair             : Sample(8),
      openInterest                               : Sample(7),
      openInterestDate                           : Sample(6),
      reason                                     : Sample(1),
      externalPriceAtSourceFractionPair          : Sample(8) ]

EncodeFuturesSummaryMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct8(message.futureProduct)
        \o message.bidPriceSummaryFractionPair
        \o message.bidSize
        \o message.askPriceSummaryFractionPair
        \o message.askSize
        \o message.lastPriceFractionPair
        \o message.openPriceFractionPair
        \o message.highPriceFractionPair
        \o message.lowPriceFractionPair
        \o message.settlementPriceFractionPair
        \o message.netChangeSign
        \o message.netChangeFuturesSummaryMessageFractionPair
        \o message.volume
        \o message.previousSettlementFractionPair
        \o message.openInterest
        \o message.openInterestDate
        \o message.reason
        \o message.externalPriceAtSourceFractionPair

DecodeFuturesSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct8(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET bidPriceSummaryFractionPair == ReadBytes(futureProduct.rest, 8) IN IF ~bidPriceSummaryFractionPair.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceSummaryFractionPair.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSummaryFractionPair == ReadBytes(bidSize.rest, 8) IN IF ~askPriceSummaryFractionPair.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceSummaryFractionPair.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceFractionPair == ReadBytes(askSize.rest, 8) IN IF ~lastPriceFractionPair.ok THEN Fail ELSE
    LET openPriceFractionPair == ReadBytes(lastPriceFractionPair.rest, 8) IN IF ~openPriceFractionPair.ok THEN Fail ELSE
    LET highPriceFractionPair == ReadBytes(openPriceFractionPair.rest, 8) IN IF ~highPriceFractionPair.ok THEN Fail ELSE
    LET lowPriceFractionPair == ReadBytes(highPriceFractionPair.rest, 8) IN IF ~lowPriceFractionPair.ok THEN Fail ELSE
    LET settlementPriceFractionPair == ReadBytes(lowPriceFractionPair.rest, 8) IN IF ~settlementPriceFractionPair.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(settlementPriceFractionPair.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFuturesSummaryMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFuturesSummaryMessageFractionPair.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeFuturesSummaryMessageFractionPair.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET previousSettlementFractionPair == ReadBytes(volume.rest, 8) IN IF ~previousSettlementFractionPair.ok THEN Fail ELSE
    LET openInterest == ReadBytes(previousSettlementFractionPair.rest, 7) IN IF ~openInterest.ok THEN Fail ELSE
    LET openInterestDate == ReadBytes(openInterest.rest, 6) IN IF ~openInterestDate.ok THEN Fail ELSE
    LET reason == ReadBytes(openInterestDate.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    LET externalPriceAtSourceFractionPair == ReadBytes(reason.rest, 8) IN IF ~externalPriceAtSourceFractionPair.ok THEN Fail ELSE
    Ok([ exchangeId                                 |-> exchangeId.value,
         futureProduct                              |-> futureProduct.value,
         bidPriceSummaryFractionPair                |-> bidPriceSummaryFractionPair.value,
         bidSize                                    |-> bidSize.value,
         askPriceSummaryFractionPair                |-> askPriceSummaryFractionPair.value,
         askSize                                    |-> askSize.value,
         lastPriceFractionPair                      |-> lastPriceFractionPair.value,
         openPriceFractionPair                      |-> openPriceFractionPair.value,
         highPriceFractionPair                      |-> highPriceFractionPair.value,
         lowPriceFractionPair                       |-> lowPriceFractionPair.value,
         settlementPriceFractionPair                |-> settlementPriceFractionPair.value,
         netChangeSign                              |-> netChangeSign.value,
         netChangeFuturesSummaryMessageFractionPair |-> netChangeFuturesSummaryMessageFractionPair.value,
         volume                                     |-> volume.value,
         previousSettlementFractionPair             |-> previousSettlementFractionPair.value,
         openInterest                               |-> openInterest.value,
         openInterestDate                           |-> openInterestDate.value,
         reason                                     |-> reason.value,
         externalPriceAtSourceFractionPair          |-> externalPriceAtSourceFractionPair.value ], externalPriceAtSourceFractionPair.rest)

ZeroFuturesSummaryMessage ==
    [ exchangeId                                 |-> [i \in 1 .. 1 |-> 0],
      futureProduct                              |-> ZeroFutureProduct8,
      bidPriceSummaryFractionPair                |-> [i \in 1 .. 8 |-> 0],
      bidSize                                    |-> [i \in 1 .. 5 |-> 0],
      askPriceSummaryFractionPair                |-> [i \in 1 .. 8 |-> 0],
      askSize                                    |-> [i \in 1 .. 5 |-> 0],
      lastPriceFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      openPriceFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      highPriceFractionPair                      |-> [i \in 1 .. 8 |-> 0],
      lowPriceFractionPair                       |-> [i \in 1 .. 8 |-> 0],
      settlementPriceFractionPair                |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                              |-> [i \in 1 .. 1 |-> 0],
      netChangeFuturesSummaryMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      volume                                     |-> [i \in 1 .. 8 |-> 0],
      previousSettlementFractionPair             |-> [i \in 1 .. 8 |-> 0],
      openInterest                               |-> [i \in 1 .. 7 |-> 0],
      openInterestDate                           |-> [i \in 1 .. 6 |-> 0],
      reason                                     |-> [i \in 1 .. 1 |-> 0],
      externalPriceAtSourceFractionPair          |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesSummaryMessage ==
    { ZeroFuturesSummaryMessage }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct8 }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lastPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.highPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.lowPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.settlementPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.netChangeFuturesSummaryMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.previousSettlementFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(7) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.openInterestDate = one] : one \in Sample(6) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }
        \cup { [ZeroFuturesSummaryMessage EXCEPT !.externalPriceAtSourceFractionPair = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Summary Message: 113 bytes                                     *)
(***************************************************************************)

StrategySummaryMessage ==
    [ exchangeId                                  : Sample(1),
      strategySymbol                              : Sample(30),
      bidPriceSign                                : Sample(1),
      bidPriceSummaryFractionPair                 : Sample(8),
      bidSize                                     : Sample(5),
      askPriceSign                                : Sample(1),
      askPriceSummaryFractionPair                 : Sample(8),
      askSize                                     : Sample(5),
      lastPriceSign                               : Sample(1),
      lastPriceFractionPair                       : Sample(8),
      openPriceSign                               : Sample(1),
      openPriceFractionPair                       : Sample(8),
      highPriceSign                               : Sample(1),
      highPriceFractionPair                       : Sample(8),
      lowPriceSign                                : Sample(1),
      lowPriceFractionPair                        : Sample(8),
      netChangeSign                               : Sample(1),
      netChangeStrategySummaryMessageFractionPair : Sample(8),
      volume                                      : Sample(8),
      reason                                      : Sample(1) ]

EncodeStrategySummaryMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.bidPriceSign
        \o message.bidPriceSummaryFractionPair
        \o message.bidSize
        \o message.askPriceSign
        \o message.askPriceSummaryFractionPair
        \o message.askSize
        \o message.lastPriceSign
        \o message.lastPriceFractionPair
        \o message.openPriceSign
        \o message.openPriceFractionPair
        \o message.highPriceSign
        \o message.highPriceFractionPair
        \o message.lowPriceSign
        \o message.lowPriceFractionPair
        \o message.netChangeSign
        \o message.netChangeStrategySummaryMessageFractionPair
        \o message.volume
        \o message.reason

DecodeStrategySummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET bidPriceSign == ReadBytes(strategySymbol.rest, 1) IN IF ~bidPriceSign.ok THEN Fail ELSE
    LET bidPriceSummaryFractionPair == ReadBytes(bidPriceSign.rest, 8) IN IF ~bidPriceSummaryFractionPair.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPriceSummaryFractionPair.rest, 5) IN IF ~bidSize.ok THEN Fail ELSE
    LET askPriceSign == ReadBytes(bidSize.rest, 1) IN IF ~askPriceSign.ok THEN Fail ELSE
    LET askPriceSummaryFractionPair == ReadBytes(askPriceSign.rest, 8) IN IF ~askPriceSummaryFractionPair.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPriceSummaryFractionPair.rest, 5) IN IF ~askSize.ok THEN Fail ELSE
    LET lastPriceSign == ReadBytes(askSize.rest, 1) IN IF ~lastPriceSign.ok THEN Fail ELSE
    LET lastPriceFractionPair == ReadBytes(lastPriceSign.rest, 8) IN IF ~lastPriceFractionPair.ok THEN Fail ELSE
    LET openPriceSign == ReadBytes(lastPriceFractionPair.rest, 1) IN IF ~openPriceSign.ok THEN Fail ELSE
    LET openPriceFractionPair == ReadBytes(openPriceSign.rest, 8) IN IF ~openPriceFractionPair.ok THEN Fail ELSE
    LET highPriceSign == ReadBytes(openPriceFractionPair.rest, 1) IN IF ~highPriceSign.ok THEN Fail ELSE
    LET highPriceFractionPair == ReadBytes(highPriceSign.rest, 8) IN IF ~highPriceFractionPair.ok THEN Fail ELSE
    LET lowPriceSign == ReadBytes(highPriceFractionPair.rest, 1) IN IF ~lowPriceSign.ok THEN Fail ELSE
    LET lowPriceFractionPair == ReadBytes(lowPriceSign.rest, 8) IN IF ~lowPriceFractionPair.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(lowPriceFractionPair.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeStrategySummaryMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeStrategySummaryMessageFractionPair.ok THEN Fail ELSE
    LET volume == ReadBytes(netChangeStrategySummaryMessageFractionPair.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET reason == ReadBytes(volume.rest, 1) IN IF ~reason.ok THEN Fail ELSE
    Ok([ exchangeId                                  |-> exchangeId.value,
         strategySymbol                              |-> strategySymbol.value,
         bidPriceSign                                |-> bidPriceSign.value,
         bidPriceSummaryFractionPair                 |-> bidPriceSummaryFractionPair.value,
         bidSize                                     |-> bidSize.value,
         askPriceSign                                |-> askPriceSign.value,
         askPriceSummaryFractionPair                 |-> askPriceSummaryFractionPair.value,
         askSize                                     |-> askSize.value,
         lastPriceSign                               |-> lastPriceSign.value,
         lastPriceFractionPair                       |-> lastPriceFractionPair.value,
         openPriceSign                               |-> openPriceSign.value,
         openPriceFractionPair                       |-> openPriceFractionPair.value,
         highPriceSign                               |-> highPriceSign.value,
         highPriceFractionPair                       |-> highPriceFractionPair.value,
         lowPriceSign                                |-> lowPriceSign.value,
         lowPriceFractionPair                        |-> lowPriceFractionPair.value,
         netChangeSign                               |-> netChangeSign.value,
         netChangeStrategySummaryMessageFractionPair |-> netChangeStrategySummaryMessageFractionPair.value,
         volume                                      |-> volume.value,
         reason                                      |-> reason.value ], reason.rest)

ZeroStrategySummaryMessage ==
    [ exchangeId                                  |-> [i \in 1 .. 1 |-> 0],
      strategySymbol                              |-> [i \in 1 .. 30 |-> 0],
      bidPriceSign                                |-> [i \in 1 .. 1 |-> 0],
      bidPriceSummaryFractionPair                 |-> [i \in 1 .. 8 |-> 0],
      bidSize                                     |-> [i \in 1 .. 5 |-> 0],
      askPriceSign                                |-> [i \in 1 .. 1 |-> 0],
      askPriceSummaryFractionPair                 |-> [i \in 1 .. 8 |-> 0],
      askSize                                     |-> [i \in 1 .. 5 |-> 0],
      lastPriceSign                               |-> [i \in 1 .. 1 |-> 0],
      lastPriceFractionPair                       |-> [i \in 1 .. 8 |-> 0],
      openPriceSign                               |-> [i \in 1 .. 1 |-> 0],
      openPriceFractionPair                       |-> [i \in 1 .. 8 |-> 0],
      highPriceSign                               |-> [i \in 1 .. 1 |-> 0],
      highPriceFractionPair                       |-> [i \in 1 .. 8 |-> 0],
      lowPriceSign                                |-> [i \in 1 .. 1 |-> 0],
      lowPriceFractionPair                        |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                               |-> [i \in 1 .. 1 |-> 0],
      netChangeStrategySummaryMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      volume                                      |-> [i \in 1 .. 8 |-> 0],
      reason                                      |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategySummaryMessage ==
    { ZeroStrategySummaryMessage }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.bidSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askPriceSummaryFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.askSize = one] : one \in Sample(5) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lastPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.openPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.highPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPriceSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.lowPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.netChangeStrategySummaryMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroStrategySummaryMessage EXCEPT !.reason = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol9 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol9(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol9(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol9 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol9 ==
    { ZeroOptionSymbol9 }
        \cup { [ZeroOptionSymbol9 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol9 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol9 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol9 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol9 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Initial And Improvement Order Message: 60 bytes                  *)
(***************************************************************************)

OptionInitialAndImprovementOrderMessage ==
    [ exchangeId             : Sample(1),
      optionSymbol           : OptionSymbol9,
      auctionId              : Sample(6),
      orderSide              : Sample(1),
      orderQuantity          : Sample(8),
      orderPriceFractionPair : Sample(8),
      orderType              : Sample(1),
      orderId                : Sample(8),
      previousOrderId        : Sample(8) ]

EncodeOptionInitialAndImprovementOrderMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol9(message.optionSymbol)
        \o message.auctionId
        \o message.orderSide
        \o message.orderQuantity
        \o message.orderPriceFractionPair
        \o message.orderType
        \o message.orderId
        \o message.previousOrderId

DecodeOptionInitialAndImprovementOrderMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol9(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(optionSymbol.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(auctionId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(orderSide.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET orderPriceFractionPair == ReadBytes(orderQuantity.rest, 8) IN IF ~orderPriceFractionPair.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderPriceFractionPair.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET previousOrderId == ReadBytes(orderId.rest, 8) IN IF ~previousOrderId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         optionSymbol           |-> optionSymbol.value,
         auctionId              |-> auctionId.value,
         orderSide              |-> orderSide.value,
         orderQuantity          |-> orderQuantity.value,
         orderPriceFractionPair |-> orderPriceFractionPair.value,
         orderType              |-> orderType.value,
         orderId                |-> orderId.value,
         previousOrderId        |-> previousOrderId.value ], previousOrderId.rest)

ZeroOptionInitialAndImprovementOrderMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      optionSymbol           |-> ZeroOptionSymbol9,
      auctionId              |-> [i \in 1 .. 6 |-> 0],
      orderSide              |-> [i \in 1 .. 1 |-> 0],
      orderQuantity          |-> [i \in 1 .. 8 |-> 0],
      orderPriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      orderType              |-> [i \in 1 .. 1 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      previousOrderId        |-> [i \in 1 .. 8 |-> 0] ]

(* Option Initial And Improvement Order Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionInitialAndImprovementOrderMessage ==
    { ZeroOptionInitialAndImprovementOrderMessage }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol9 }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.orderPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOptionInitialAndImprovementOrderMessage EXCEPT !.previousOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Initial And Improvement Order Message: 71 bytes                *)
(***************************************************************************)

StrategyInitialAndImprovementOrderMessage ==
    [ exchangeId             : Sample(1),
      strategySymbol         : Sample(30),
      auctionId              : Sample(6),
      orderSide              : Sample(1),
      orderQuantity          : Sample(8),
      orderPriceFractionPair : Sample(8),
      orderType              : Sample(1),
      orderId                : Sample(8),
      previousOrderId        : Sample(8) ]

EncodeStrategyInitialAndImprovementOrderMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.auctionId
        \o message.orderSide
        \o message.orderQuantity
        \o message.orderPriceFractionPair
        \o message.orderType
        \o message.orderId
        \o message.previousOrderId

DecodeStrategyInitialAndImprovementOrderMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategySymbol.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    LET orderSide == ReadBytes(auctionId.rest, 1) IN IF ~orderSide.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(orderSide.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET orderPriceFractionPair == ReadBytes(orderQuantity.rest, 8) IN IF ~orderPriceFractionPair.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderPriceFractionPair.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET previousOrderId == ReadBytes(orderId.rest, 8) IN IF ~previousOrderId.ok THEN Fail ELSE
    Ok([ exchangeId             |-> exchangeId.value,
         strategySymbol         |-> strategySymbol.value,
         auctionId              |-> auctionId.value,
         orderSide              |-> orderSide.value,
         orderQuantity          |-> orderQuantity.value,
         orderPriceFractionPair |-> orderPriceFractionPair.value,
         orderType              |-> orderType.value,
         orderId                |-> orderId.value,
         previousOrderId        |-> previousOrderId.value ], previousOrderId.rest)

ZeroStrategyInitialAndImprovementOrderMessage ==
    [ exchangeId             |-> [i \in 1 .. 1 |-> 0],
      strategySymbol         |-> [i \in 1 .. 30 |-> 0],
      auctionId              |-> [i \in 1 .. 6 |-> 0],
      orderSide              |-> [i \in 1 .. 1 |-> 0],
      orderQuantity          |-> [i \in 1 .. 8 |-> 0],
      orderPriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      orderType              |-> [i \in 1 .. 1 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      previousOrderId        |-> [i \in 1 .. 8 |-> 0] ]

(* Strategy Initial And Improvement Order Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyInitialAndImprovementOrderMessage ==
    { ZeroStrategyInitialAndImprovementOrderMessage }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.auctionId = one] : one \in Sample(6) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.orderSide = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.orderPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroStrategyInitialAndImprovementOrderMessage EXCEPT !.previousOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Beginning Of Options Summary Message: 1 bytes                           *)
(***************************************************************************)

BeginningOfOptionsSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfOptionsSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfOptionsSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfOptionsSummaryMessage ==
    { ZeroBeginningOfOptionsSummaryMessage }
        \cup { [ZeroBeginningOfOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Future Options Summary Message: 1 bytes                    *)
(***************************************************************************)

BeginningOfFutureOptionsSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfFutureOptionsSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfFutureOptionsSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfFutureOptionsSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Future Options Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfFutureOptionsSummaryMessage ==
    { ZeroBeginningOfFutureOptionsSummaryMessage }
        \cup { [ZeroBeginningOfFutureOptionsSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Futures Summary Message: 1 bytes                           *)
(***************************************************************************)

BeginningOfFuturesSummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfFuturesSummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfFuturesSummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfFuturesSummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Futures Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfFuturesSummaryMessage ==
    { ZeroBeginningOfFuturesSummaryMessage }
        \cup { [ZeroBeginningOfFuturesSummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Beginning Of Strategy Summary Message: 1 bytes                          *)
(***************************************************************************)

BeginningOfStrategySummaryMessage ==
    [ exchangeId : Sample(1) ]

EncodeBeginningOfStrategySummaryMessage(message) ==
    message.exchangeId

DecodeBeginningOfStrategySummaryMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value ], exchangeId.rest)

ZeroBeginningOfStrategySummaryMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0] ]

(* Beginning Of Strategy Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedBeginningOfStrategySummaryMessage ==
    { ZeroBeginningOfStrategySummaryMessage }
        \cup { [ZeroBeginningOfStrategySummaryMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Symbol: 19 bytes                                                 *)
(***************************************************************************)

OptionSymbol10 ==
    [ rootSymbol              : Sample(6),
      expiryMonth             : Sample(1),
      strikePriceFractionPair : Sample(8),
      expiryYear              : Sample(2),
      expiryDay               : Sample(2) ]

EncodeOptionSymbol10(message) ==
    message.rootSymbol
        \o message.expiryMonth
        \o message.strikePriceFractionPair
        \o message.expiryYear
        \o message.expiryDay

DecodeOptionSymbol10(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET expiryMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~expiryMonth.ok THEN Fail ELSE
    LET strikePriceFractionPair == ReadBytes(expiryMonth.rest, 8) IN IF ~strikePriceFractionPair.ok THEN Fail ELSE
    LET expiryYear == ReadBytes(strikePriceFractionPair.rest, 2) IN IF ~expiryYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(expiryYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol              |-> rootSymbol.value,
         expiryMonth             |-> expiryMonth.value,
         strikePriceFractionPair |-> strikePriceFractionPair.value,
         expiryYear              |-> expiryYear.value,
         expiryDay               |-> expiryDay.value ], expiryDay.rest)

ZeroOptionSymbol10 ==
    [ rootSymbol              |-> [i \in 1 .. 6 |-> 0],
      expiryMonth             |-> [i \in 1 .. 1 |-> 0],
      strikePriceFractionPair |-> [i \in 1 .. 8 |-> 0],
      expiryYear              |-> [i \in 1 .. 2 |-> 0],
      expiryDay               |-> [i \in 1 .. 2 |-> 0] ]

(* Option Symbol at zero, then each field in turn at the values it is checked at *)
CheckedOptionSymbol10 ==
    { ZeroOptionSymbol10 }
        \cup { [ZeroOptionSymbol10 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionSymbol10 EXCEPT !.expiryMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionSymbol10 EXCEPT !.strikePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroOptionSymbol10 EXCEPT !.expiryYear = one] : one \in Sample(2) }
        \cup { [ZeroOptionSymbol10 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Option Auction Ending Message: 26 bytes                                 *)
(***************************************************************************)

OptionAuctionEndingMessage ==
    [ exchangeId   : Sample(1),
      optionSymbol : OptionSymbol10,
      auctionId    : Sample(6) ]

EncodeOptionAuctionEndingMessage(message) ==
    message.exchangeId
        \o EncodeOptionSymbol10(message.optionSymbol)
        \o message.auctionId

DecodeOptionAuctionEndingMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET optionSymbol == DecodeOptionSymbol10(exchangeId.rest) IN IF ~optionSymbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(optionSymbol.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId   |-> exchangeId.value,
         optionSymbol |-> optionSymbol.value,
         auctionId    |-> auctionId.value ], auctionId.rest)

ZeroOptionAuctionEndingMessage ==
    [ exchangeId   |-> [i \in 1 .. 1 |-> 0],
      optionSymbol |-> ZeroOptionSymbol10,
      auctionId    |-> [i \in 1 .. 6 |-> 0] ]

(* Option Auction Ending Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionAuctionEndingMessage ==
    { ZeroOptionAuctionEndingMessage }
        \cup { [ZeroOptionAuctionEndingMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroOptionAuctionEndingMessage EXCEPT !.optionSymbol = one] : one \in CheckedOptionSymbol10 }
        \cup { [ZeroOptionAuctionEndingMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Strategy Auction Ending Message: 37 bytes                               *)
(***************************************************************************)

StrategyAuctionEndingMessage ==
    [ exchangeId     : Sample(1),
      strategySymbol : Sample(30),
      auctionId      : Sample(6) ]

EncodeStrategyAuctionEndingMessage(message) ==
    message.exchangeId
        \o message.strategySymbol
        \o message.auctionId

DecodeStrategyAuctionEndingMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET strategySymbol == ReadBytes(exchangeId.rest, 30) IN IF ~strategySymbol.ok THEN Fail ELSE
    LET auctionId == ReadBytes(strategySymbol.rest, 6) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ exchangeId     |-> exchangeId.value,
         strategySymbol |-> strategySymbol.value,
         auctionId      |-> auctionId.value ], auctionId.rest)

ZeroStrategyAuctionEndingMessage ==
    [ exchangeId     |-> [i \in 1 .. 1 |-> 0],
      strategySymbol |-> [i \in 1 .. 30 |-> 0],
      auctionId      |-> [i \in 1 .. 6 |-> 0] ]

(* Strategy Auction Ending Message at zero, then each field in turn at the values it is checked at *)
CheckedStrategyAuctionEndingMessage ==
    { ZeroStrategyAuctionEndingMessage }
        \cup { [ZeroStrategyAuctionEndingMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStrategyAuctionEndingMessage EXCEPT !.strategySymbol = one] : one \in Sample(30) }
        \cup { [ZeroStrategyAuctionEndingMessage EXCEPT !.auctionId = one] : one \in Sample(6) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct9 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct9(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct9(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct9 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct9 ==
    { ZeroFutureProduct9 }
        \cup { [ZeroFutureProduct9 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct9 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct9 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct9 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Futures Trade Correction Message: 46 bytes                              *)
(***************************************************************************)

FuturesTradeCorrectionMessage ==
    [ exchangeId                                         : Sample(1),
      futureProduct                                      : FutureProduct9,
      volume                                             : Sample(8),
      tradePriceFractionPair                             : Sample(8),
      netChangeSign                                      : Sample(1),
      netChangeFuturesTradeCorrectionMessageFractionPair : Sample(8),
      priceIndicatorMarker                               : Sample(1),
      tradeNumber                                        : Sample(8) ]

EncodeFuturesTradeCorrectionMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct9(message.futureProduct)
        \o message.volume
        \o message.tradePriceFractionPair
        \o message.netChangeSign
        \o message.netChangeFuturesTradeCorrectionMessageFractionPair
        \o message.priceIndicatorMarker
        \o message.tradeNumber

DecodeFuturesTradeCorrectionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct9(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET volume == ReadBytes(futureProduct.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET tradePriceFractionPair == ReadBytes(volume.rest, 8) IN IF ~tradePriceFractionPair.ok THEN Fail ELSE
    LET netChangeSign == ReadBytes(tradePriceFractionPair.rest, 1) IN IF ~netChangeSign.ok THEN Fail ELSE
    LET netChangeFuturesTradeCorrectionMessageFractionPair == ReadBytes(netChangeSign.rest, 8) IN IF ~netChangeFuturesTradeCorrectionMessageFractionPair.ok THEN Fail ELSE
    LET priceIndicatorMarker == ReadBytes(netChangeFuturesTradeCorrectionMessageFractionPair.rest, 1) IN IF ~priceIndicatorMarker.ok THEN Fail ELSE
    LET tradeNumber == ReadBytes(priceIndicatorMarker.rest, 8) IN IF ~tradeNumber.ok THEN Fail ELSE
    Ok([ exchangeId                                         |-> exchangeId.value,
         futureProduct                                      |-> futureProduct.value,
         volume                                             |-> volume.value,
         tradePriceFractionPair                             |-> tradePriceFractionPair.value,
         netChangeSign                                      |-> netChangeSign.value,
         netChangeFuturesTradeCorrectionMessageFractionPair |-> netChangeFuturesTradeCorrectionMessageFractionPair.value,
         priceIndicatorMarker                               |-> priceIndicatorMarker.value,
         tradeNumber                                        |-> tradeNumber.value ], tradeNumber.rest)

ZeroFuturesTradeCorrectionMessage ==
    [ exchangeId                                         |-> [i \in 1 .. 1 |-> 0],
      futureProduct                                      |-> ZeroFutureProduct9,
      volume                                             |-> [i \in 1 .. 8 |-> 0],
      tradePriceFractionPair                             |-> [i \in 1 .. 8 |-> 0],
      netChangeSign                                      |-> [i \in 1 .. 1 |-> 0],
      netChangeFuturesTradeCorrectionMessageFractionPair |-> [i \in 1 .. 8 |-> 0],
      priceIndicatorMarker                               |-> [i \in 1 .. 1 |-> 0],
      tradeNumber                                        |-> [i \in 1 .. 8 |-> 0] ]

(* Futures Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedFuturesTradeCorrectionMessage ==
    { ZeroFuturesTradeCorrectionMessage }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct9 }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradePriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChangeSign = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.netChangeFuturesTradeCorrectionMessageFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.priceIndicatorMarker = one] : one \in Sample(1) }
        \cup { [ZeroFuturesTradeCorrectionMessage EXCEPT !.tradeNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Group Status Message: 8 bytes                                           *)
(***************************************************************************)

GroupStatusMessage ==
    [ exchangeId      : Sample(1),
      rootSymbolGroup : Sample(6),
      groupStatus     : Sample(1) ]

EncodeGroupStatusMessage(message) ==
    message.exchangeId
        \o message.rootSymbolGroup
        \o message.groupStatus

DecodeGroupStatusMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET rootSymbolGroup == ReadBytes(exchangeId.rest, 6) IN IF ~rootSymbolGroup.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(rootSymbolGroup.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ exchangeId      |-> exchangeId.value,
         rootSymbolGroup |-> rootSymbolGroup.value,
         groupStatus     |-> groupStatus.value ], groupStatus.rest)

ZeroGroupStatusMessage ==
    [ exchangeId      |-> [i \in 1 .. 1 |-> 0],
      rootSymbolGroup |-> [i \in 1 .. 6 |-> 0],
      groupStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* Group Status Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupStatusMessage ==
    { ZeroGroupStatusMessage }
        \cup { [ZeroGroupStatusMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.rootSymbolGroup = one] : one \in Sample(6) }
        \cup { [ZeroGroupStatusMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Group Status Strategies Message: 4 bytes                                *)
(***************************************************************************)

GroupStatusStrategiesMessage ==
    [ exchangeId      : Sample(1),
      groupInstrument : Sample(2),
      groupStatus     : Sample(1) ]

EncodeGroupStatusStrategiesMessage(message) ==
    message.exchangeId
        \o message.groupInstrument
        \o message.groupStatus

DecodeGroupStatusStrategiesMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET groupInstrument == ReadBytes(exchangeId.rest, 2) IN IF ~groupInstrument.ok THEN Fail ELSE
    LET groupStatus == ReadBytes(groupInstrument.rest, 1) IN IF ~groupStatus.ok THEN Fail ELSE
    Ok([ exchangeId      |-> exchangeId.value,
         groupInstrument |-> groupInstrument.value,
         groupStatus     |-> groupStatus.value ], groupStatus.rest)

ZeroGroupStatusStrategiesMessage ==
    [ exchangeId      |-> [i \in 1 .. 1 |-> 0],
      groupInstrument |-> [i \in 1 .. 2 |-> 0],
      groupStatus     |-> [i \in 1 .. 1 |-> 0] ]

(* Group Status Strategies Message at zero, then each field in turn at the values it is checked at *)
CheckedGroupStatusStrategiesMessage ==
    { ZeroGroupStatusStrategiesMessage }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.groupInstrument = one] : one \in Sample(2) }
        \cup { [ZeroGroupStatusStrategiesMessage EXCEPT !.groupStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Future Product: 11 bytes                                                *)
(***************************************************************************)

FutureProduct10 ==
    [ rootSymbol  : Sample(6),
      symbolMonth : Sample(1),
      symbolYear  : Sample(2),
      expiryDay   : Sample(2) ]

EncodeFutureProduct10(message) ==
    message.rootSymbol
        \o message.symbolMonth
        \o message.symbolYear
        \o message.expiryDay

DecodeFutureProduct10(bytes) ==
    LET rootSymbol == ReadBytes(bytes, 6) IN IF ~rootSymbol.ok THEN Fail ELSE
    LET symbolMonth == ReadBytes(rootSymbol.rest, 1) IN IF ~symbolMonth.ok THEN Fail ELSE
    LET symbolYear == ReadBytes(symbolMonth.rest, 2) IN IF ~symbolYear.ok THEN Fail ELSE
    LET expiryDay == ReadBytes(symbolYear.rest, 2) IN IF ~expiryDay.ok THEN Fail ELSE
    Ok([ rootSymbol  |-> rootSymbol.value,
         symbolMonth |-> symbolMonth.value,
         symbolYear  |-> symbolYear.value,
         expiryDay   |-> expiryDay.value ], expiryDay.rest)

ZeroFutureProduct10 ==
    [ rootSymbol  |-> [i \in 1 .. 6 |-> 0],
      symbolMonth |-> [i \in 1 .. 1 |-> 0],
      symbolYear  |-> [i \in 1 .. 2 |-> 0],
      expiryDay   |-> [i \in 1 .. 2 |-> 0] ]

(* Future Product at zero, then each field in turn at the values it is checked at *)
CheckedFutureProduct10 ==
    { ZeroFutureProduct10 }
        \cup { [ZeroFutureProduct10 EXCEPT !.rootSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFutureProduct10 EXCEPT !.symbolMonth = one] : one \in Sample(1) }
        \cup { [ZeroFutureProduct10 EXCEPT !.symbolYear = one] : one \in Sample(2) }
        \cup { [ZeroFutureProduct10 EXCEPT !.expiryDay = one] : one \in Sample(2) }

(***************************************************************************)
(* Bond Definition: 32 bytes                                               *)
(***************************************************************************)

BondDefinition ==
    [ maturityDate                 : Sample(8),
      couponFractionPair           : Sample(8),
      outstandingBondValue         : Sample(8),
      conversionFactorFractionPair : Sample(8) ]

EncodeBondDefinition(message) ==
    message.maturityDate
        \o message.couponFractionPair
        \o message.outstandingBondValue
        \o message.conversionFactorFractionPair

DecodeBondDefinition(bytes) ==
    LET maturityDate == ReadBytes(bytes, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET couponFractionPair == ReadBytes(maturityDate.rest, 8) IN IF ~couponFractionPair.ok THEN Fail ELSE
    LET outstandingBondValue == ReadBytes(couponFractionPair.rest, 8) IN IF ~outstandingBondValue.ok THEN Fail ELSE
    LET conversionFactorFractionPair == ReadBytes(outstandingBondValue.rest, 8) IN IF ~conversionFactorFractionPair.ok THEN Fail ELSE
    Ok([ maturityDate                 |-> maturityDate.value,
         couponFractionPair           |-> couponFractionPair.value,
         outstandingBondValue         |-> outstandingBondValue.value,
         conversionFactorFractionPair |-> conversionFactorFractionPair.value ], conversionFactorFractionPair.rest)

ZeroBondDefinition ==
    [ maturityDate                 |-> [i \in 1 .. 8 |-> 0],
      couponFractionPair           |-> [i \in 1 .. 8 |-> 0],
      outstandingBondValue         |-> [i \in 1 .. 8 |-> 0],
      conversionFactorFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Bond Definition at zero, then each field in turn at the values it is checked at *)
CheckedBondDefinition ==
    { ZeroBondDefinition }
        \cup { [ZeroBondDefinition EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroBondDefinition EXCEPT !.couponFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroBondDefinition EXCEPT !.outstandingBondValue = one] : one \in Sample(8) }
        \cup { [ZeroBondDefinition EXCEPT !.conversionFactorFractionPair = one] : one \in Sample(8) }

(* A run of Bond Definition, written one after another *)
RECURSIVE EncodeBondDefinitionList(_)
EncodeBondDefinitionList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBondDefinition(Head(messages)) \o EncodeBondDefinitionList(Tail(messages))

(* As many Bond Definition as the field that counts them says *)
RECURSIVE ReadBondDefinitionList(_, _)
ReadBondDefinitionList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBondDefinition(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBondDefinitionList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Bond Definition of each kind, for the lists that carry them *)
OneBondDefinition == { ZeroBondDefinition }

(***************************************************************************)
(* Future Deliverables Message                                             *)
(***************************************************************************)

FutureDeliverablesMessage ==
    [ exchangeId     : Sample(1),
      futureProduct  : FutureProduct10,
      bondDefinition : SampleLists(OneBondDefinition) ]

EncodeFutureDeliverablesMessage(message) ==
    message.exchangeId
        \o EncodeFutureProduct10(message.futureProduct)
        \o EncodeDigits(Len(message.bondDefinition), 2)
        \o EncodeBondDefinitionList(message.bondDefinition)

DecodeFutureDeliverablesMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET futureProduct == DecodeFutureProduct10(exchangeId.rest) IN IF ~futureProduct.ok THEN Fail ELSE
    LET numberOfBonds == ReadDigits(futureProduct.rest, 2) IN IF ~numberOfBonds.ok THEN Fail ELSE
    LET bondDefinition == ReadBondDefinitionList(numberOfBonds.rest, numberOfBonds.value) IN IF ~bondDefinition.ok THEN Fail ELSE
    Ok([ exchangeId     |-> exchangeId.value,
         futureProduct  |-> futureProduct.value,
         bondDefinition |-> bondDefinition.value ], bondDefinition.rest)

ZeroFutureDeliverablesMessage ==
    [ exchangeId     |-> [i \in 1 .. 1 |-> 0],
      futureProduct  |-> ZeroFutureProduct10,
      bondDefinition |-> << >> ]

(* Future Deliverables Message at zero, then each field in turn at the values it is checked at *)
CheckedFutureDeliverablesMessage ==
    { ZeroFutureDeliverablesMessage }
        \cup { [ZeroFutureDeliverablesMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroFutureDeliverablesMessage EXCEPT !.futureProduct = one] : one \in CheckedFutureProduct10 }
        \cup { [ZeroFutureDeliverablesMessage EXCEPT !.bondDefinition = one] : one \in SampleLists(OneBondDefinition) }

(***************************************************************************)
(* Regular Text Bulletin: 80 bytes                                         *)
(***************************************************************************)

RegularTextBulletin ==
    [ regularBulletinContents : Sample(79),
      continueMarker          : Sample(1) ]

EncodeRegularTextBulletin(message) ==
    message.regularBulletinContents
        \o message.continueMarker

DecodeRegularTextBulletin(bytes) ==
    LET regularBulletinContents == ReadBytes(bytes, 79) IN IF ~regularBulletinContents.ok THEN Fail ELSE
    LET continueMarker == ReadBytes(regularBulletinContents.rest, 1) IN IF ~continueMarker.ok THEN Fail ELSE
    Ok([ regularBulletinContents |-> regularBulletinContents.value,
         continueMarker          |-> continueMarker.value ], continueMarker.rest)

ZeroRegularTextBulletin ==
    [ regularBulletinContents |-> [i \in 1 .. 79 |-> 0],
      continueMarker          |-> [i \in 1 .. 1 |-> 0] ]

(* Regular Text Bulletin at zero, then each field in turn at the values it is checked at *)
CheckedRegularTextBulletin ==
    { ZeroRegularTextBulletin }
        \cup { [ZeroRegularTextBulletin EXCEPT !.regularBulletinContents = one] : one \in Sample(79) }
        \cup { [ZeroRegularTextBulletin EXCEPT !.continueMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Special Text Bulletin: 80 bytes                                         *)
(***************************************************************************)

SpecialTextBulletin ==
    [ symbol                  : Sample(30),
      specialBulletinContents : Sample(49),
      continueMarker          : Sample(1) ]

EncodeSpecialTextBulletin(message) ==
    message.symbol
        \o message.specialBulletinContents
        \o message.continueMarker

DecodeSpecialTextBulletin(bytes) ==
    LET symbol == ReadBytes(bytes, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET specialBulletinContents == ReadBytes(symbol.rest, 49) IN IF ~specialBulletinContents.ok THEN Fail ELSE
    LET continueMarker == ReadBytes(specialBulletinContents.rest, 1) IN IF ~continueMarker.ok THEN Fail ELSE
    Ok([ symbol                  |-> symbol.value,
         specialBulletinContents |-> specialBulletinContents.value,
         continueMarker          |-> continueMarker.value ], continueMarker.rest)

ZeroSpecialTextBulletin ==
    [ symbol                  |-> [i \in 1 .. 30 |-> 0],
      specialBulletinContents |-> [i \in 1 .. 49 |-> 0],
      continueMarker          |-> [i \in 1 .. 1 |-> 0] ]

(* Special Text Bulletin at zero, then each field in turn at the values it is checked at *)
CheckedSpecialTextBulletin ==
    { ZeroSpecialTextBulletin }
        \cup { [ZeroSpecialTextBulletin EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroSpecialTextBulletin EXCEPT !.specialBulletinContents = one] : one \in Sample(49) }
        \cup { [ZeroSpecialTextBulletin EXCEPT !.continueMarker = one] : one \in Sample(1) }

(***************************************************************************)
(* Bulletin, selected by Bulletin Type                                     *)
(***************************************************************************)

RegularTextBulletinCode == 49  \* "1"
SpecialTextBulletinCode == 50  \* "2"

Bulletin ==
    [ tag : {RegularTextBulletinCode}, body : RegularTextBulletin ]
        \cup [ tag : {SpecialTextBulletinCode}, body : SpecialTextBulletin ]

EncodeBulletin(message) ==
    CASE message.tag = RegularTextBulletinCode -> EncodeRegularTextBulletin(message.body)
      [] message.tag = SpecialTextBulletinCode -> EncodeSpecialTextBulletin(message.body)

DecodeBulletin(tag, bytes) ==
    LET read ==
            CASE tag = RegularTextBulletinCode -> DecodeRegularTextBulletin(bytes)
              [] tag = SpecialTextBulletinCode -> DecodeSpecialTextBulletin(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroBulletin == [tag |-> RegularTextBulletinCode, body |-> ZeroRegularTextBulletin]

(* Each Bulletin in turn, at the values the message it names is checked at *)
CheckedBulletin ==
    { [tag |-> RegularTextBulletinCode, body |-> one] : one \in CheckedRegularTextBulletin }
        \cup { [tag |-> SpecialTextBulletinCode, body |-> one] : one \in CheckedSpecialTextBulletin }

(***************************************************************************)
(* Bulletins Message                                                       *)
(***************************************************************************)

BulletinsMessage ==
    [ reserved : Sample(1),
      bulletin : Bulletin ]

EncodeBulletinsMessage(message) ==
    message.reserved
        \o EncodeUIntBE(message.bulletin.tag, 1)
        \o EncodeBulletin(message.bulletin)

DecodeBulletinsMessage(bytes) ==
    LET reserved == ReadBytes(bytes, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET bulletinType == ReadUIntBE(reserved.rest, 1) IN IF ~bulletinType.ok THEN Fail ELSE
    LET bulletin == DecodeBulletin(bulletinType.value, bulletinType.rest) IN IF ~bulletin.ok THEN Fail ELSE
    Ok([ reserved |-> reserved.value,
         bulletin |-> bulletin.value ], bulletin.rest)

ZeroBulletinsMessage ==
    [ reserved |-> [i \in 1 .. 1 |-> 0],
      bulletin |-> ZeroBulletin ]

(* Bulletins Message at zero, then each field in turn at the values it is checked at *)
CheckedBulletinsMessage ==
    { ZeroBulletinsMessage }
        \cup { [ZeroBulletinsMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroBulletinsMessage EXCEPT !.bulletin = one] : one \in CheckedBulletin }

(***************************************************************************)
(* End Of Sales Message: 7 bytes                                           *)
(***************************************************************************)

EndOfSalesMessage ==
    [ reserved : Sample(1),
      time     : Sample(6) ]

EncodeEndOfSalesMessage(message) ==
    message.reserved
        \o message.time

DecodeEndOfSalesMessage(bytes) ==
    LET reserved == ReadBytes(bytes, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET time == ReadBytes(reserved.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ reserved |-> reserved.value,
         time     |-> time.value ], time.rest)

ZeroEndOfSalesMessage ==
    [ reserved |-> [i \in 1 .. 1 |-> 0],
      time     |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Sales Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSalesMessage ==
    { ZeroEndOfSalesMessage }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroEndOfSalesMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Tick Entry: 16 bytes                                                    *)
(***************************************************************************)

TickEntry ==
    [ minPriceFractionPair  : Sample(8),
      tickPriceFractionPair : Sample(8) ]

EncodeTickEntry(message) ==
    message.minPriceFractionPair
        \o message.tickPriceFractionPair

DecodeTickEntry(bytes) ==
    LET minPriceFractionPair == ReadBytes(bytes, 8) IN IF ~minPriceFractionPair.ok THEN Fail ELSE
    LET tickPriceFractionPair == ReadBytes(minPriceFractionPair.rest, 8) IN IF ~tickPriceFractionPair.ok THEN Fail ELSE
    Ok([ minPriceFractionPair  |-> minPriceFractionPair.value,
         tickPriceFractionPair |-> tickPriceFractionPair.value ], tickPriceFractionPair.rest)

ZeroTickEntry ==
    [ minPriceFractionPair  |-> [i \in 1 .. 8 |-> 0],
      tickPriceFractionPair |-> [i \in 1 .. 8 |-> 0] ]

(* Tick Entry at zero, then each field in turn at the values it is checked at *)
CheckedTickEntry ==
    { ZeroTickEntry }
        \cup { [ZeroTickEntry EXCEPT !.minPriceFractionPair = one] : one \in Sample(8) }
        \cup { [ZeroTickEntry EXCEPT !.tickPriceFractionPair = one] : one \in Sample(8) }

(* A run of Tick Entry, written one after another *)
RECURSIVE EncodeTickEntryList(_)
EncodeTickEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTickEntry(Head(messages)) \o EncodeTickEntryList(Tail(messages))

(* As many Tick Entry as the field that counts them says *)
RECURSIVE ReadTickEntryList(_, _)
ReadTickEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTickEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTickEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tick Entry of each kind, for the lists that carry them *)
OneTickEntry == { ZeroTickEntry }

(***************************************************************************)
(* Tick Table Message                                                      *)
(***************************************************************************)

TickTableMessage ==
    [ exchangeId         : Sample(1),
      tickTableName      : Sample(50),
      tickTableShortName : Sample(2),
      tickEntry          : SampleLists(OneTickEntry) ]

EncodeTickTableMessage(message) ==
    message.exchangeId
        \o message.tickTableName
        \o message.tickTableShortName
        \o EncodeDigits(Len(message.tickEntry), 2)
        \o EncodeTickEntryList(message.tickEntry)

DecodeTickTableMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET tickTableName == ReadBytes(exchangeId.rest, 50) IN IF ~tickTableName.ok THEN Fail ELSE
    LET tickTableShortName == ReadBytes(tickTableName.rest, 2) IN IF ~tickTableShortName.ok THEN Fail ELSE
    LET numberOfEntries == ReadDigits(tickTableShortName.rest, 2) IN IF ~numberOfEntries.ok THEN Fail ELSE
    LET tickEntry == ReadTickEntryList(numberOfEntries.rest, numberOfEntries.value) IN IF ~tickEntry.ok THEN Fail ELSE
    Ok([ exchangeId         |-> exchangeId.value,
         tickTableName      |-> tickTableName.value,
         tickTableShortName |-> tickTableShortName.value,
         tickEntry          |-> tickEntry.value ], tickEntry.rest)

ZeroTickTableMessage ==
    [ exchangeId         |-> [i \in 1 .. 1 |-> 0],
      tickTableName      |-> [i \in 1 .. 50 |-> 0],
      tickTableShortName |-> [i \in 1 .. 2 |-> 0],
      tickEntry          |-> << >> ]

(* Tick Table Message at zero, then each field in turn at the values it is checked at *)
CheckedTickTableMessage ==
    { ZeroTickTableMessage }
        \cup { [ZeroTickTableMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickTableName = one] : one \in Sample(50) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickTableShortName = one] : one \in Sample(2) }
        \cup { [ZeroTickTableMessage EXCEPT !.tickEntry = one] : one \in SampleLists(OneTickEntry) }

(***************************************************************************)
(* End Of Transmission Message: 7 bytes                                    *)
(***************************************************************************)

EndOfTransmissionMessage ==
    [ exchangeId : Sample(1),
      time       : Sample(6) ]

EncodeEndOfTransmissionMessage(message) ==
    message.exchangeId
        \o message.time

DecodeEndOfTransmissionMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET time == ReadBytes(exchangeId.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ exchangeId |-> exchangeId.value,
         time       |-> time.value ], time.rest)

ZeroEndOfTransmissionMessage ==
    [ exchangeId |-> [i \in 1 .. 1 |-> 0],
      time       |-> [i \in 1 .. 6 |-> 0] ]

(* End Of Transmission Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfTransmissionMessage ==
    { ZeroEndOfTransmissionMessage }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroEndOfTransmissionMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Circuit Assurance Message: 6 bytes                                      *)
(***************************************************************************)

CircuitAssuranceMessage ==
    [ time : Sample(6) ]

EncodeCircuitAssuranceMessage(message) ==
    message.time

DecodeCircuitAssuranceMessage(bytes) ==
    LET time == ReadBytes(bytes, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ time |-> time.value ], time.rest)

ZeroCircuitAssuranceMessage ==
    [ time |-> [i \in 1 .. 6 |-> 0] ]

(* Circuit Assurance Message at zero, then each field in turn at the values it is checked at *)
CheckedCircuitAssuranceMessage ==
    { ZeroCircuitAssuranceMessage }
        \cup { [ZeroCircuitAssuranceMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Start Of Day Message: 9 bytes                                           *)
(***************************************************************************)

StartOfDayMessage ==
    [ exchangeId   : Sample(1),
      businessDate : Sample(8) ]

EncodeStartOfDayMessage(message) ==
    message.exchangeId
        \o message.businessDate

DecodeStartOfDayMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 1) IN IF ~exchangeId.ok THEN Fail ELSE
    LET businessDate == ReadBytes(exchangeId.rest, 8) IN IF ~businessDate.ok THEN Fail ELSE
    Ok([ exchangeId   |-> exchangeId.value,
         businessDate |-> businessDate.value ], businessDate.rest)

ZeroStartOfDayMessage ==
    [ exchangeId   |-> [i \in 1 .. 1 |-> 0],
      businessDate |-> [i \in 1 .. 8 |-> 0] ]

(* Start Of Day Message at zero, then each field in turn at the values it is checked at *)
CheckedStartOfDayMessage ==
    { ZeroStartOfDayMessage }
        \cup { [ZeroStartOfDayMessage EXCEPT !.exchangeId = one] : one \in Sample(1) }
        \cup { [ZeroStartOfDayMessage EXCEPT !.businessDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

OptionTradeMessageCode == 17184  \* "C "
FutureOptionsTradeMessageCode == 17218  \* "CB"
FuturesTradeMessageCode == 17222  \* "CF"
StrategyTradeMessageCode == 17235  \* "CS"
OptionRequestForQuoteMessageCode == 17440  \* "D "
FutureOptionsRequestForQuoteMessageCode == 17474  \* "DB"
FutureRequestForQuoteMessageCode == 17478  \* "DF"
StrategyRequestForQuoteMessageCode == 17491  \* "DS"
InstrumentScheduleNoticeOptionMessageCode == 17696  \* "E "
InstrumentScheduleNoticeFuturesOptionMessageCode == 17730  \* "EB"
InstrumentScheduleNoticeFutureMessageCode == 17734  \* "EF"
InstrumentScheduleNoticeStrategyMessageCode == 17747  \* "ES"
OptionQuoteMessageCode == 17952  \* "F "
FutureOptionsQuoteMessageCode == 17986  \* "FB"
FuturesQuoteMessageCode == 17990  \* "FF"
StrategyQuoteMessageCode == 18003  \* "FS"
OptionMarketDepthMessageCode == 18464  \* "H "
FutureOptionsMarketDepthMessageCode == 18498  \* "HB"
FuturesMarketDepthMessageCode == 18502  \* "HF"
StrategyMarketDepthMessageCode == 18515  \* "HS"
OptionTradeCancellationMessageCode == 18720  \* "I "
FutureOptionsTradeCancellationMessageCode == 18754  \* "IB"
FutureTradeCancellationMessageCode == 18758  \* "IF"
StrategyTradeCancellationMessageCode == 18771  \* "IS"
OptionInstrumentKeysMessageCode == 18976  \* "J "
FutureOptionsInstrumentKeysMessageCode == 19010  \* "JB"
UnderlyingInstrumentKeysMessageCode == 19013  \* "JE"
FuturesInstrumentKeysMessageCode == 19014  \* "JF"
StrategyInstrumentKeysMessageCode == 19027  \* "JS"
OptionAuctionBeginningMessageCode == 19744  \* "M "
StrategyAuctionBeginningMessageCode == 19795  \* "MS"
OptionSummaryMessageCode == 20000  \* "N "
FutureOptionsSummaryMessageCode == 20034  \* "NB"
FuturesSummaryMessageCode == 20038  \* "NF"
StrategySummaryMessageCode == 20051  \* "NS"
OptionInitialAndImprovementOrderMessageCode == 20256  \* "O "
StrategyInitialAndImprovementOrderMessageCode == 20307  \* "OS"
BeginningOfOptionsSummaryMessageCode == 20768  \* "Q "
BeginningOfFutureOptionsSummaryMessageCode == 20802  \* "QB"
BeginningOfFuturesSummaryMessageCode == 20806  \* "QF"
BeginningOfStrategySummaryMessageCode == 20819  \* "QS"
OptionAuctionEndingMessageCode == 21536  \* "T "
StrategyAuctionEndingMessageCode == 21587  \* "TS"
FuturesTradeCorrectionMessageCode == 22598  \* "XF"
GroupStatusMessageCode == 18258  \* "GR"
GroupStatusStrategiesMessageCode == 18259  \* "GS"
FutureDeliverablesMessageCode == 19270  \* "KF"
BulletinsMessageCode == 19488  \* "L "
EndOfSalesMessageCode == 21280  \* "S "
TickTableMessageCode == 21588  \* "TT"
EndOfTransmissionMessageCode == 21792  \* "U "
CircuitAssuranceMessageCode == 22048  \* "V "
StartOfDayMessageCode == 21316  \* "SD"

MessageBody ==
    [ tag : {OptionTradeMessageCode}, body : OptionTradeMessage ]
        \cup [ tag : {FutureOptionsTradeMessageCode}, body : FutureOptionsTradeMessage ]
        \cup [ tag : {FuturesTradeMessageCode}, body : FuturesTradeMessage ]
        \cup [ tag : {StrategyTradeMessageCode}, body : StrategyTradeMessage ]
        \cup [ tag : {OptionRequestForQuoteMessageCode}, body : OptionRequestForQuoteMessage ]
        \cup [ tag : {FutureOptionsRequestForQuoteMessageCode}, body : FutureOptionsRequestForQuoteMessage ]
        \cup [ tag : {FutureRequestForQuoteMessageCode}, body : FutureRequestForQuoteMessage ]
        \cup [ tag : {StrategyRequestForQuoteMessageCode}, body : StrategyRequestForQuoteMessage ]
        \cup [ tag : {InstrumentScheduleNoticeOptionMessageCode}, body : InstrumentScheduleNoticeOptionMessage ]
        \cup [ tag : {InstrumentScheduleNoticeFuturesOptionMessageCode}, body : InstrumentScheduleNoticeFuturesOptionMessage ]
        \cup [ tag : {InstrumentScheduleNoticeFutureMessageCode}, body : InstrumentScheduleNoticeFutureMessage ]
        \cup [ tag : {InstrumentScheduleNoticeStrategyMessageCode}, body : InstrumentScheduleNoticeStrategyMessage ]
        \cup [ tag : {OptionQuoteMessageCode}, body : OptionQuoteMessage ]
        \cup [ tag : {FutureOptionsQuoteMessageCode}, body : FutureOptionsQuoteMessage ]
        \cup [ tag : {FuturesQuoteMessageCode}, body : FuturesQuoteMessage ]
        \cup [ tag : {StrategyQuoteMessageCode}, body : StrategyQuoteMessage ]
        \cup [ tag : {OptionMarketDepthMessageCode}, body : OptionMarketDepthMessage ]
        \cup [ tag : {FutureOptionsMarketDepthMessageCode}, body : FutureOptionsMarketDepthMessage ]
        \cup [ tag : {FuturesMarketDepthMessageCode}, body : FuturesMarketDepthMessage ]
        \cup [ tag : {StrategyMarketDepthMessageCode}, body : StrategyMarketDepthMessage ]
        \cup [ tag : {OptionTradeCancellationMessageCode}, body : OptionTradeCancellationMessage ]
        \cup [ tag : {FutureOptionsTradeCancellationMessageCode}, body : FutureOptionsTradeCancellationMessage ]
        \cup [ tag : {FutureTradeCancellationMessageCode}, body : FutureTradeCancellationMessage ]
        \cup [ tag : {StrategyTradeCancellationMessageCode}, body : StrategyTradeCancellationMessage ]
        \cup [ tag : {OptionInstrumentKeysMessageCode}, body : OptionInstrumentKeysMessage ]
        \cup [ tag : {FutureOptionsInstrumentKeysMessageCode}, body : FutureOptionsInstrumentKeysMessage ]
        \cup [ tag : {UnderlyingInstrumentKeysMessageCode}, body : UnderlyingInstrumentKeysMessage ]
        \cup [ tag : {FuturesInstrumentKeysMessageCode}, body : FuturesInstrumentKeysMessage ]
        \cup [ tag : {StrategyInstrumentKeysMessageCode}, body : StrategyInstrumentKeysMessage ]
        \cup [ tag : {OptionAuctionBeginningMessageCode}, body : OptionAuctionBeginningMessage ]
        \cup [ tag : {StrategyAuctionBeginningMessageCode}, body : StrategyAuctionBeginningMessage ]
        \cup [ tag : {OptionSummaryMessageCode}, body : OptionSummaryMessage ]
        \cup [ tag : {FutureOptionsSummaryMessageCode}, body : FutureOptionsSummaryMessage ]
        \cup [ tag : {FuturesSummaryMessageCode}, body : FuturesSummaryMessage ]
        \cup [ tag : {StrategySummaryMessageCode}, body : StrategySummaryMessage ]
        \cup [ tag : {OptionInitialAndImprovementOrderMessageCode}, body : OptionInitialAndImprovementOrderMessage ]
        \cup [ tag : {StrategyInitialAndImprovementOrderMessageCode}, body : StrategyInitialAndImprovementOrderMessage ]
        \cup [ tag : {BeginningOfOptionsSummaryMessageCode}, body : BeginningOfOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfFutureOptionsSummaryMessageCode}, body : BeginningOfFutureOptionsSummaryMessage ]
        \cup [ tag : {BeginningOfFuturesSummaryMessageCode}, body : BeginningOfFuturesSummaryMessage ]
        \cup [ tag : {BeginningOfStrategySummaryMessageCode}, body : BeginningOfStrategySummaryMessage ]
        \cup [ tag : {OptionAuctionEndingMessageCode}, body : OptionAuctionEndingMessage ]
        \cup [ tag : {StrategyAuctionEndingMessageCode}, body : StrategyAuctionEndingMessage ]
        \cup [ tag : {FuturesTradeCorrectionMessageCode}, body : FuturesTradeCorrectionMessage ]
        \cup [ tag : {GroupStatusMessageCode}, body : GroupStatusMessage ]
        \cup [ tag : {GroupStatusStrategiesMessageCode}, body : GroupStatusStrategiesMessage ]
        \cup [ tag : {FutureDeliverablesMessageCode}, body : FutureDeliverablesMessage ]
        \cup [ tag : {BulletinsMessageCode}, body : BulletinsMessage ]
        \cup [ tag : {EndOfSalesMessageCode}, body : EndOfSalesMessage ]
        \cup [ tag : {TickTableMessageCode}, body : TickTableMessage ]
        \cup [ tag : {EndOfTransmissionMessageCode}, body : EndOfTransmissionMessage ]
        \cup [ tag : {CircuitAssuranceMessageCode}, body : CircuitAssuranceMessage ]
        \cup [ tag : {StartOfDayMessageCode}, body : StartOfDayMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = OptionTradeMessageCode -> EncodeOptionTradeMessage(message.body)
      [] message.tag = FutureOptionsTradeMessageCode -> EncodeFutureOptionsTradeMessage(message.body)
      [] message.tag = FuturesTradeMessageCode -> EncodeFuturesTradeMessage(message.body)
      [] message.tag = StrategyTradeMessageCode -> EncodeStrategyTradeMessage(message.body)
      [] message.tag = OptionRequestForQuoteMessageCode -> EncodeOptionRequestForQuoteMessage(message.body)
      [] message.tag = FutureOptionsRequestForQuoteMessageCode -> EncodeFutureOptionsRequestForQuoteMessage(message.body)
      [] message.tag = FutureRequestForQuoteMessageCode -> EncodeFutureRequestForQuoteMessage(message.body)
      [] message.tag = StrategyRequestForQuoteMessageCode -> EncodeStrategyRequestForQuoteMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeOptionMessageCode -> EncodeInstrumentScheduleNoticeOptionMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeFuturesOptionMessageCode -> EncodeInstrumentScheduleNoticeFuturesOptionMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeFutureMessageCode -> EncodeInstrumentScheduleNoticeFutureMessage(message.body)
      [] message.tag = InstrumentScheduleNoticeStrategyMessageCode -> EncodeInstrumentScheduleNoticeStrategyMessage(message.body)
      [] message.tag = OptionQuoteMessageCode -> EncodeOptionQuoteMessage(message.body)
      [] message.tag = FutureOptionsQuoteMessageCode -> EncodeFutureOptionsQuoteMessage(message.body)
      [] message.tag = FuturesQuoteMessageCode -> EncodeFuturesQuoteMessage(message.body)
      [] message.tag = StrategyQuoteMessageCode -> EncodeStrategyQuoteMessage(message.body)
      [] message.tag = OptionMarketDepthMessageCode -> EncodeOptionMarketDepthMessage(message.body)
      [] message.tag = FutureOptionsMarketDepthMessageCode -> EncodeFutureOptionsMarketDepthMessage(message.body)
      [] message.tag = FuturesMarketDepthMessageCode -> EncodeFuturesMarketDepthMessage(message.body)
      [] message.tag = StrategyMarketDepthMessageCode -> EncodeStrategyMarketDepthMessage(message.body)
      [] message.tag = OptionTradeCancellationMessageCode -> EncodeOptionTradeCancellationMessage(message.body)
      [] message.tag = FutureOptionsTradeCancellationMessageCode -> EncodeFutureOptionsTradeCancellationMessage(message.body)
      [] message.tag = FutureTradeCancellationMessageCode -> EncodeFutureTradeCancellationMessage(message.body)
      [] message.tag = StrategyTradeCancellationMessageCode -> EncodeStrategyTradeCancellationMessage(message.body)
      [] message.tag = OptionInstrumentKeysMessageCode -> EncodeOptionInstrumentKeysMessage(message.body)
      [] message.tag = FutureOptionsInstrumentKeysMessageCode -> EncodeFutureOptionsInstrumentKeysMessage(message.body)
      [] message.tag = UnderlyingInstrumentKeysMessageCode -> EncodeUnderlyingInstrumentKeysMessage(message.body)
      [] message.tag = FuturesInstrumentKeysMessageCode -> EncodeFuturesInstrumentKeysMessage(message.body)
      [] message.tag = StrategyInstrumentKeysMessageCode -> EncodeStrategyInstrumentKeysMessage(message.body)
      [] message.tag = OptionAuctionBeginningMessageCode -> EncodeOptionAuctionBeginningMessage(message.body)
      [] message.tag = StrategyAuctionBeginningMessageCode -> EncodeStrategyAuctionBeginningMessage(message.body)
      [] message.tag = OptionSummaryMessageCode -> EncodeOptionSummaryMessage(message.body)
      [] message.tag = FutureOptionsSummaryMessageCode -> EncodeFutureOptionsSummaryMessage(message.body)
      [] message.tag = FuturesSummaryMessageCode -> EncodeFuturesSummaryMessage(message.body)
      [] message.tag = StrategySummaryMessageCode -> EncodeStrategySummaryMessage(message.body)
      [] message.tag = OptionInitialAndImprovementOrderMessageCode -> EncodeOptionInitialAndImprovementOrderMessage(message.body)
      [] message.tag = StrategyInitialAndImprovementOrderMessageCode -> EncodeStrategyInitialAndImprovementOrderMessage(message.body)
      [] message.tag = BeginningOfOptionsSummaryMessageCode -> EncodeBeginningOfOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfFutureOptionsSummaryMessageCode -> EncodeBeginningOfFutureOptionsSummaryMessage(message.body)
      [] message.tag = BeginningOfFuturesSummaryMessageCode -> EncodeBeginningOfFuturesSummaryMessage(message.body)
      [] message.tag = BeginningOfStrategySummaryMessageCode -> EncodeBeginningOfStrategySummaryMessage(message.body)
      [] message.tag = OptionAuctionEndingMessageCode -> EncodeOptionAuctionEndingMessage(message.body)
      [] message.tag = StrategyAuctionEndingMessageCode -> EncodeStrategyAuctionEndingMessage(message.body)
      [] message.tag = FuturesTradeCorrectionMessageCode -> EncodeFuturesTradeCorrectionMessage(message.body)
      [] message.tag = GroupStatusMessageCode -> EncodeGroupStatusMessage(message.body)
      [] message.tag = GroupStatusStrategiesMessageCode -> EncodeGroupStatusStrategiesMessage(message.body)
      [] message.tag = FutureDeliverablesMessageCode -> EncodeFutureDeliverablesMessage(message.body)
      [] message.tag = BulletinsMessageCode -> EncodeBulletinsMessage(message.body)
      [] message.tag = EndOfSalesMessageCode -> EncodeEndOfSalesMessage(message.body)
      [] message.tag = TickTableMessageCode -> EncodeTickTableMessage(message.body)
      [] message.tag = EndOfTransmissionMessageCode -> EncodeEndOfTransmissionMessage(message.body)
      [] message.tag = CircuitAssuranceMessageCode -> EncodeCircuitAssuranceMessage(message.body)
      [] message.tag = StartOfDayMessageCode -> EncodeStartOfDayMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = OptionTradeMessageCode -> DecodeOptionTradeMessage(bytes)
              [] tag = FutureOptionsTradeMessageCode -> DecodeFutureOptionsTradeMessage(bytes)
              [] tag = FuturesTradeMessageCode -> DecodeFuturesTradeMessage(bytes)
              [] tag = StrategyTradeMessageCode -> DecodeStrategyTradeMessage(bytes)
              [] tag = OptionRequestForQuoteMessageCode -> DecodeOptionRequestForQuoteMessage(bytes)
              [] tag = FutureOptionsRequestForQuoteMessageCode -> DecodeFutureOptionsRequestForQuoteMessage(bytes)
              [] tag = FutureRequestForQuoteMessageCode -> DecodeFutureRequestForQuoteMessage(bytes)
              [] tag = StrategyRequestForQuoteMessageCode -> DecodeStrategyRequestForQuoteMessage(bytes)
              [] tag = InstrumentScheduleNoticeOptionMessageCode -> DecodeInstrumentScheduleNoticeOptionMessage(bytes)
              [] tag = InstrumentScheduleNoticeFuturesOptionMessageCode -> DecodeInstrumentScheduleNoticeFuturesOptionMessage(bytes)
              [] tag = InstrumentScheduleNoticeFutureMessageCode -> DecodeInstrumentScheduleNoticeFutureMessage(bytes)
              [] tag = InstrumentScheduleNoticeStrategyMessageCode -> DecodeInstrumentScheduleNoticeStrategyMessage(bytes)
              [] tag = OptionQuoteMessageCode -> DecodeOptionQuoteMessage(bytes)
              [] tag = FutureOptionsQuoteMessageCode -> DecodeFutureOptionsQuoteMessage(bytes)
              [] tag = FuturesQuoteMessageCode -> DecodeFuturesQuoteMessage(bytes)
              [] tag = StrategyQuoteMessageCode -> DecodeStrategyQuoteMessage(bytes)
              [] tag = OptionMarketDepthMessageCode -> DecodeOptionMarketDepthMessage(bytes)
              [] tag = FutureOptionsMarketDepthMessageCode -> DecodeFutureOptionsMarketDepthMessage(bytes)
              [] tag = FuturesMarketDepthMessageCode -> DecodeFuturesMarketDepthMessage(bytes)
              [] tag = StrategyMarketDepthMessageCode -> DecodeStrategyMarketDepthMessage(bytes)
              [] tag = OptionTradeCancellationMessageCode -> DecodeOptionTradeCancellationMessage(bytes)
              [] tag = FutureOptionsTradeCancellationMessageCode -> DecodeFutureOptionsTradeCancellationMessage(bytes)
              [] tag = FutureTradeCancellationMessageCode -> DecodeFutureTradeCancellationMessage(bytes)
              [] tag = StrategyTradeCancellationMessageCode -> DecodeStrategyTradeCancellationMessage(bytes)
              [] tag = OptionInstrumentKeysMessageCode -> DecodeOptionInstrumentKeysMessage(bytes)
              [] tag = FutureOptionsInstrumentKeysMessageCode -> DecodeFutureOptionsInstrumentKeysMessage(bytes)
              [] tag = UnderlyingInstrumentKeysMessageCode -> DecodeUnderlyingInstrumentKeysMessage(bytes)
              [] tag = FuturesInstrumentKeysMessageCode -> DecodeFuturesInstrumentKeysMessage(bytes)
              [] tag = StrategyInstrumentKeysMessageCode -> DecodeStrategyInstrumentKeysMessage(bytes)
              [] tag = OptionAuctionBeginningMessageCode -> DecodeOptionAuctionBeginningMessage(bytes)
              [] tag = StrategyAuctionBeginningMessageCode -> DecodeStrategyAuctionBeginningMessage(bytes)
              [] tag = OptionSummaryMessageCode -> DecodeOptionSummaryMessage(bytes)
              [] tag = FutureOptionsSummaryMessageCode -> DecodeFutureOptionsSummaryMessage(bytes)
              [] tag = FuturesSummaryMessageCode -> DecodeFuturesSummaryMessage(bytes)
              [] tag = StrategySummaryMessageCode -> DecodeStrategySummaryMessage(bytes)
              [] tag = OptionInitialAndImprovementOrderMessageCode -> DecodeOptionInitialAndImprovementOrderMessage(bytes)
              [] tag = StrategyInitialAndImprovementOrderMessageCode -> DecodeStrategyInitialAndImprovementOrderMessage(bytes)
              [] tag = BeginningOfOptionsSummaryMessageCode -> DecodeBeginningOfOptionsSummaryMessage(bytes)
              [] tag = BeginningOfFutureOptionsSummaryMessageCode -> DecodeBeginningOfFutureOptionsSummaryMessage(bytes)
              [] tag = BeginningOfFuturesSummaryMessageCode -> DecodeBeginningOfFuturesSummaryMessage(bytes)
              [] tag = BeginningOfStrategySummaryMessageCode -> DecodeBeginningOfStrategySummaryMessage(bytes)
              [] tag = OptionAuctionEndingMessageCode -> DecodeOptionAuctionEndingMessage(bytes)
              [] tag = StrategyAuctionEndingMessageCode -> DecodeStrategyAuctionEndingMessage(bytes)
              [] tag = FuturesTradeCorrectionMessageCode -> DecodeFuturesTradeCorrectionMessage(bytes)
              [] tag = GroupStatusMessageCode -> DecodeGroupStatusMessage(bytes)
              [] tag = GroupStatusStrategiesMessageCode -> DecodeGroupStatusStrategiesMessage(bytes)
              [] tag = FutureDeliverablesMessageCode -> DecodeFutureDeliverablesMessage(bytes)
              [] tag = BulletinsMessageCode -> DecodeBulletinsMessage(bytes)
              [] tag = EndOfSalesMessageCode -> DecodeEndOfSalesMessage(bytes)
              [] tag = TickTableMessageCode -> DecodeTickTableMessage(bytes)
              [] tag = EndOfTransmissionMessageCode -> DecodeEndOfTransmissionMessage(bytes)
              [] tag = CircuitAssuranceMessageCode -> DecodeCircuitAssuranceMessage(bytes)
              [] tag = StartOfDayMessageCode -> DecodeStartOfDayMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> OptionTradeMessageCode, body |-> ZeroOptionTradeMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> OptionTradeMessageCode, body |-> one] : one \in CheckedOptionTradeMessage }
        \cup { [tag |-> FutureOptionsTradeMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeMessage }
        \cup { [tag |-> FuturesTradeMessageCode, body |-> one] : one \in CheckedFuturesTradeMessage }
        \cup { [tag |-> StrategyTradeMessageCode, body |-> one] : one \in CheckedStrategyTradeMessage }
        \cup { [tag |-> OptionRequestForQuoteMessageCode, body |-> one] : one \in CheckedOptionRequestForQuoteMessage }
        \cup { [tag |-> FutureOptionsRequestForQuoteMessageCode, body |-> one] : one \in CheckedFutureOptionsRequestForQuoteMessage }
        \cup { [tag |-> FutureRequestForQuoteMessageCode, body |-> one] : one \in CheckedFutureRequestForQuoteMessage }
        \cup { [tag |-> StrategyRequestForQuoteMessageCode, body |-> one] : one \in CheckedStrategyRequestForQuoteMessage }
        \cup { [tag |-> InstrumentScheduleNoticeOptionMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeOptionMessage }
        \cup { [tag |-> InstrumentScheduleNoticeFuturesOptionMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeFuturesOptionMessage }
        \cup { [tag |-> InstrumentScheduleNoticeFutureMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeFutureMessage }
        \cup { [tag |-> InstrumentScheduleNoticeStrategyMessageCode, body |-> one] : one \in CheckedInstrumentScheduleNoticeStrategyMessage }
        \cup { [tag |-> OptionQuoteMessageCode, body |-> one] : one \in CheckedOptionQuoteMessage }
        \cup { [tag |-> FutureOptionsQuoteMessageCode, body |-> one] : one \in CheckedFutureOptionsQuoteMessage }
        \cup { [tag |-> FuturesQuoteMessageCode, body |-> one] : one \in CheckedFuturesQuoteMessage }
        \cup { [tag |-> StrategyQuoteMessageCode, body |-> one] : one \in CheckedStrategyQuoteMessage }
        \cup { [tag |-> OptionMarketDepthMessageCode, body |-> one] : one \in CheckedOptionMarketDepthMessage }
        \cup { [tag |-> FutureOptionsMarketDepthMessageCode, body |-> one] : one \in CheckedFutureOptionsMarketDepthMessage }
        \cup { [tag |-> FuturesMarketDepthMessageCode, body |-> one] : one \in CheckedFuturesMarketDepthMessage }
        \cup { [tag |-> StrategyMarketDepthMessageCode, body |-> one] : one \in CheckedStrategyMarketDepthMessage }
        \cup { [tag |-> OptionTradeCancellationMessageCode, body |-> one] : one \in CheckedOptionTradeCancellationMessage }
        \cup { [tag |-> FutureOptionsTradeCancellationMessageCode, body |-> one] : one \in CheckedFutureOptionsTradeCancellationMessage }
        \cup { [tag |-> FutureTradeCancellationMessageCode, body |-> one] : one \in CheckedFutureTradeCancellationMessage }
        \cup { [tag |-> StrategyTradeCancellationMessageCode, body |-> one] : one \in CheckedStrategyTradeCancellationMessage }
        \cup { [tag |-> OptionInstrumentKeysMessageCode, body |-> one] : one \in CheckedOptionInstrumentKeysMessage }
        \cup { [tag |-> FutureOptionsInstrumentKeysMessageCode, body |-> one] : one \in CheckedFutureOptionsInstrumentKeysMessage }
        \cup { [tag |-> UnderlyingInstrumentKeysMessageCode, body |-> one] : one \in CheckedUnderlyingInstrumentKeysMessage }
        \cup { [tag |-> FuturesInstrumentKeysMessageCode, body |-> one] : one \in CheckedFuturesInstrumentKeysMessage }
        \cup { [tag |-> StrategyInstrumentKeysMessageCode, body |-> one] : one \in CheckedStrategyInstrumentKeysMessage }
        \cup { [tag |-> OptionAuctionBeginningMessageCode, body |-> one] : one \in CheckedOptionAuctionBeginningMessage }
        \cup { [tag |-> StrategyAuctionBeginningMessageCode, body |-> one] : one \in CheckedStrategyAuctionBeginningMessage }
        \cup { [tag |-> OptionSummaryMessageCode, body |-> one] : one \in CheckedOptionSummaryMessage }
        \cup { [tag |-> FutureOptionsSummaryMessageCode, body |-> one] : one \in CheckedFutureOptionsSummaryMessage }
        \cup { [tag |-> FuturesSummaryMessageCode, body |-> one] : one \in CheckedFuturesSummaryMessage }
        \cup { [tag |-> StrategySummaryMessageCode, body |-> one] : one \in CheckedStrategySummaryMessage }
        \cup { [tag |-> OptionInitialAndImprovementOrderMessageCode, body |-> one] : one \in CheckedOptionInitialAndImprovementOrderMessage }
        \cup { [tag |-> StrategyInitialAndImprovementOrderMessageCode, body |-> one] : one \in CheckedStrategyInitialAndImprovementOrderMessage }
        \cup { [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfFutureOptionsSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfFutureOptionsSummaryMessage }
        \cup { [tag |-> BeginningOfFuturesSummaryMessageCode, body |-> one] : one \in CheckedBeginningOfFuturesSummaryMessage }
        \cup { [tag |-> BeginningOfStrategySummaryMessageCode, body |-> one] : one \in CheckedBeginningOfStrategySummaryMessage }
        \cup { [tag |-> OptionAuctionEndingMessageCode, body |-> one] : one \in CheckedOptionAuctionEndingMessage }
        \cup { [tag |-> StrategyAuctionEndingMessageCode, body |-> one] : one \in CheckedStrategyAuctionEndingMessage }
        \cup { [tag |-> FuturesTradeCorrectionMessageCode, body |-> one] : one \in CheckedFuturesTradeCorrectionMessage }
        \cup { [tag |-> GroupStatusMessageCode, body |-> one] : one \in CheckedGroupStatusMessage }
        \cup { [tag |-> GroupStatusStrategiesMessageCode, body |-> one] : one \in CheckedGroupStatusStrategiesMessage }
        \cup { [tag |-> FutureDeliverablesMessageCode, body |-> one] : one \in CheckedFutureDeliverablesMessage }
        \cup { [tag |-> BulletinsMessageCode, body |-> one] : one \in CheckedBulletinsMessage }
        \cup { [tag |-> EndOfSalesMessageCode, body |-> one] : one \in CheckedEndOfSalesMessage }
        \cup { [tag |-> TickTableMessageCode, body |-> one] : one \in CheckedTickTableMessage }
        \cup { [tag |-> EndOfTransmissionMessageCode, body |-> one] : one \in CheckedEndOfTransmissionMessage }
        \cup { [tag |-> CircuitAssuranceMessageCode, body |-> one] : one \in CheckedCircuitAssuranceMessage }
        \cup { [tag |-> StartOfDayMessageCode, body |-> one] : one \in CheckedStartOfDayMessage }

(***************************************************************************)
(* Sola Frame                                                              *)
(***************************************************************************)

SolaFrame ==
    [ solaMessageStart : Sample(1),
      sequenceNumber   : Sample(10),
      messageTimestamp : Sample(20),
      messageBody      : MessageBody,
      solaMessageEnd   : Sample(1) ]

EncodeSolaFrame(message) ==
    message.solaMessageStart
        \o message.sequenceNumber
        \o EncodeUIntBE(message.messageBody.tag, 2)
        \o message.messageTimestamp
        \o EncodeMessageBody(message.messageBody)
        \o message.solaMessageEnd

DecodeSolaFrame(bytes) ==
    LET solaMessageStart == ReadBytes(bytes, 1) IN IF ~solaMessageStart.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(solaMessageStart.rest, 10) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageTimestamp == ReadBytes(messageType.rest, 20) IN IF ~messageTimestamp.ok THEN Fail ELSE
    LET messageBody == DecodeMessageBody(messageType.value, messageTimestamp.rest) IN IF ~messageBody.ok THEN Fail ELSE
    LET solaMessageEnd == ReadBytes(messageBody.rest, 1) IN IF ~solaMessageEnd.ok THEN Fail ELSE
    Ok([ solaMessageStart |-> solaMessageStart.value,
         sequenceNumber   |-> sequenceNumber.value,
         messageTimestamp |-> messageTimestamp.value,
         messageBody      |-> messageBody.value,
         solaMessageEnd   |-> solaMessageEnd.value ], solaMessageEnd.rest)

ZeroSolaFrame ==
    [ solaMessageStart |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber   |-> [i \in 1 .. 10 |-> 0],
      messageTimestamp |-> [i \in 1 .. 20 |-> 0],
      messageBody      |-> ZeroMessageBody,
      solaMessageEnd   |-> [i \in 1 .. 1 |-> 0] ]

(* Sola Frame at zero, then each field in turn at the values it is checked at *)
CheckedSolaFrame ==
    { ZeroSolaFrame }
        \cup { [ZeroSolaFrame EXCEPT !.solaMessageStart = one] : one \in Sample(1) }
        \cup { [ZeroSolaFrame EXCEPT !.sequenceNumber = one] : one \in Sample(10) }
        \cup { [ZeroSolaFrame EXCEPT !.messageTimestamp = one] : one \in Sample(20) }
        \cup { [ZeroSolaFrame EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroSolaFrame EXCEPT !.solaMessageEnd = one] : one \in Sample(1) }

(* A run of Sola Frame, written one after another *)
RECURSIVE EncodeSolaFrameList(_)
EncodeSolaFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSolaFrame(Head(messages)) \o EncodeSolaFrameList(Tail(messages))

(* As many Sola Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSolaFrameAll(_)
ReadSolaFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSolaFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSolaFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sola Frame of each kind, for the lists that carry them *)
OneSolaFrame ==
    { [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionTradeMessageCode, body |-> ZeroOptionTradeMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsTradeMessageCode, body |-> ZeroFutureOptionsTradeMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FuturesTradeMessageCode, body |-> ZeroFuturesTradeMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyTradeMessageCode, body |-> ZeroStrategyTradeMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionRequestForQuoteMessageCode, body |-> ZeroOptionRequestForQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsRequestForQuoteMessageCode, body |-> ZeroFutureOptionsRequestForQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureRequestForQuoteMessageCode, body |-> ZeroFutureRequestForQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyRequestForQuoteMessageCode, body |-> ZeroStrategyRequestForQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeOptionMessageCode, body |-> ZeroInstrumentScheduleNoticeOptionMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeFuturesOptionMessageCode, body |-> ZeroInstrumentScheduleNoticeFuturesOptionMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeFutureMessageCode, body |-> ZeroInstrumentScheduleNoticeFutureMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> InstrumentScheduleNoticeStrategyMessageCode, body |-> ZeroInstrumentScheduleNoticeStrategyMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionQuoteMessageCode, body |-> ZeroOptionQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsQuoteMessageCode, body |-> ZeroFutureOptionsQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FuturesQuoteMessageCode, body |-> ZeroFuturesQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyQuoteMessageCode, body |-> ZeroStrategyQuoteMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionMarketDepthMessageCode, body |-> ZeroOptionMarketDepthMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsMarketDepthMessageCode, body |-> ZeroFutureOptionsMarketDepthMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FuturesMarketDepthMessageCode, body |-> ZeroFuturesMarketDepthMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyMarketDepthMessageCode, body |-> ZeroStrategyMarketDepthMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionTradeCancellationMessageCode, body |-> ZeroOptionTradeCancellationMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsTradeCancellationMessageCode, body |-> ZeroFutureOptionsTradeCancellationMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureTradeCancellationMessageCode, body |-> ZeroFutureTradeCancellationMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyTradeCancellationMessageCode, body |-> ZeroStrategyTradeCancellationMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionInstrumentKeysMessageCode, body |-> ZeroOptionInstrumentKeysMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsInstrumentKeysMessageCode, body |-> ZeroFutureOptionsInstrumentKeysMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> UnderlyingInstrumentKeysMessageCode, body |-> ZeroUnderlyingInstrumentKeysMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FuturesInstrumentKeysMessageCode, body |-> ZeroFuturesInstrumentKeysMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyInstrumentKeysMessageCode, body |-> ZeroStrategyInstrumentKeysMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionAuctionBeginningMessageCode, body |-> ZeroOptionAuctionBeginningMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyAuctionBeginningMessageCode, body |-> ZeroStrategyAuctionBeginningMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionSummaryMessageCode, body |-> ZeroOptionSummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureOptionsSummaryMessageCode, body |-> ZeroFutureOptionsSummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FuturesSummaryMessageCode, body |-> ZeroFuturesSummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategySummaryMessageCode, body |-> ZeroStrategySummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionInitialAndImprovementOrderMessageCode, body |-> ZeroOptionInitialAndImprovementOrderMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyInitialAndImprovementOrderMessageCode, body |-> ZeroStrategyInitialAndImprovementOrderMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> BeginningOfOptionsSummaryMessageCode, body |-> ZeroBeginningOfOptionsSummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> BeginningOfFutureOptionsSummaryMessageCode, body |-> ZeroBeginningOfFutureOptionsSummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> BeginningOfFuturesSummaryMessageCode, body |-> ZeroBeginningOfFuturesSummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> BeginningOfStrategySummaryMessageCode, body |-> ZeroBeginningOfStrategySummaryMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> OptionAuctionEndingMessageCode, body |-> ZeroOptionAuctionEndingMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StrategyAuctionEndingMessageCode, body |-> ZeroStrategyAuctionEndingMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FuturesTradeCorrectionMessageCode, body |-> ZeroFuturesTradeCorrectionMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> GroupStatusMessageCode, body |-> ZeroGroupStatusMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> GroupStatusStrategiesMessageCode, body |-> ZeroGroupStatusStrategiesMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> FutureDeliverablesMessageCode, body |-> ZeroFutureDeliverablesMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> BulletinsMessageCode, body |-> ZeroBulletinsMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> EndOfSalesMessageCode, body |-> ZeroEndOfSalesMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> TickTableMessageCode, body |-> ZeroTickTableMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> EndOfTransmissionMessageCode, body |-> ZeroEndOfTransmissionMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> CircuitAssuranceMessageCode, body |-> ZeroCircuitAssuranceMessage]],
      [ZeroSolaFrame EXCEPT !.messageBody = [tag |-> StartOfDayMessageCode, body |-> ZeroStartOfDayMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ solaFrame : SampleLists(OneSolaFrame) ]

EncodePacket(message) ==
    EncodeSolaFrameList(message.solaFrame)

DecodePacket(bytes) ==
    LET solaFrame == ReadSolaFrameAll(bytes) IN IF ~solaFrame.ok THEN Fail ELSE
    Ok([ solaFrame |-> solaFrame.value ], solaFrame.rest)

ZeroPacket ==
    [ solaFrame |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.solaFrame = one] : one \in SampleLists(OneSolaFrame) }

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

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol ==
    \A message \in CheckedOptionSymbol :
        LET read == DecodeOptionSymbol(EncodeOptionSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeMessage ==
    \A message \in CheckedOptionTradeMessage :
        LET read == DecodeOptionTradeMessage(EncodeOptionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol ==
    \A message \in CheckedFutureOptionSymbol :
        LET read == DecodeFutureOptionSymbol(EncodeFutureOptionSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsTradeMessage ==
    \A message \in CheckedFutureOptionsTradeMessage :
        LET read == DecodeFutureOptionsTradeMessage(EncodeFutureOptionsTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct ==
    \A message \in CheckedFutureProduct :
        LET read == DecodeFutureProduct(EncodeFutureProduct(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesTradeMessage ==
    \A message \in CheckedFuturesTradeMessage :
        LET read == DecodeFuturesTradeMessage(EncodeFuturesTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeMessage ==
    \A message \in CheckedStrategyTradeMessage :
        LET read == DecodeStrategyTradeMessage(EncodeStrategyTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol2 ==
    \A message \in CheckedOptionSymbol2 :
        LET read == DecodeOptionSymbol2(EncodeOptionSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Request For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionRequestForQuoteMessage ==
    \A message \in CheckedOptionRequestForQuoteMessage :
        LET read == DecodeOptionRequestForQuoteMessage(EncodeOptionRequestForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol2 ==
    \A message \in CheckedFutureOptionSymbol2 :
        LET read == DecodeFutureOptionSymbol2(EncodeFutureOptionSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Request For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsRequestForQuoteMessage ==
    \A message \in CheckedFutureOptionsRequestForQuoteMessage :
        LET read == DecodeFutureOptionsRequestForQuoteMessage(EncodeFutureOptionsRequestForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct2 ==
    \A message \in CheckedFutureProduct2 :
        LET read == DecodeFutureProduct2(EncodeFutureProduct2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Request For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureRequestForQuoteMessage ==
    \A message \in CheckedFutureRequestForQuoteMessage :
        LET read == DecodeFutureRequestForQuoteMessage(EncodeFutureRequestForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Request For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyRequestForQuoteMessage ==
    \A message \in CheckedStrategyRequestForQuoteMessage :
        LET read == DecodeStrategyRequestForQuoteMessage(EncodeStrategyRequestForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol Schedule Notice decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbolScheduleNotice ==
    \A message \in CheckedOptionSymbolScheduleNotice :
        LET read == DecodeOptionSymbolScheduleNotice(EncodeOptionSymbolScheduleNotice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Option Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeOptionMessage ==
    \A message \in CheckedInstrumentScheduleNoticeOptionMessage :
        LET read == DecodeInstrumentScheduleNoticeOptionMessage(EncodeInstrumentScheduleNoticeOptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol3 ==
    \A message \in CheckedFutureOptionSymbol3 :
        LET read == DecodeFutureOptionSymbol3(EncodeFutureOptionSymbol3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Futures Option Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeFuturesOptionMessage ==
    \A message \in CheckedInstrumentScheduleNoticeFuturesOptionMessage :
        LET read == DecodeInstrumentScheduleNoticeFuturesOptionMessage(EncodeInstrumentScheduleNoticeFuturesOptionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct3 ==
    \A message \in CheckedFutureProduct3 :
        LET read == DecodeFutureProduct3(EncodeFutureProduct3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Future Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeFutureMessage ==
    \A message \in CheckedInstrumentScheduleNoticeFutureMessage :
        LET read == DecodeInstrumentScheduleNoticeFutureMessage(EncodeInstrumentScheduleNoticeFutureMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Schedule Notice Strategy Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentScheduleNoticeStrategyMessage ==
    \A message \in CheckedInstrumentScheduleNoticeStrategyMessage :
        LET read == DecodeInstrumentScheduleNoticeStrategyMessage(EncodeInstrumentScheduleNoticeStrategyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol3 ==
    \A message \in CheckedOptionSymbol3 :
        LET read == DecodeOptionSymbol3(EncodeOptionSymbol3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionQuoteMessage ==
    \A message \in CheckedOptionQuoteMessage :
        LET read == DecodeOptionQuoteMessage(EncodeOptionQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol4 ==
    \A message \in CheckedFutureOptionSymbol4 :
        LET read == DecodeFutureOptionSymbol4(EncodeFutureOptionSymbol4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsQuoteMessage ==
    \A message \in CheckedFutureOptionsQuoteMessage :
        LET read == DecodeFutureOptionsQuoteMessage(EncodeFutureOptionsQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct4 ==
    \A message \in CheckedFutureProduct4 :
        LET read == DecodeFutureProduct4(EncodeFutureProduct4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesQuoteMessage ==
    \A message \in CheckedFuturesQuoteMessage :
        LET read == DecodeFuturesQuoteMessage(EncodeFuturesQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyQuoteMessage ==
    \A message \in CheckedStrategyQuoteMessage :
        LET read == DecodeStrategyQuoteMessage(EncodeStrategyQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol4 ==
    \A message \in CheckedOptionSymbol4 :
        LET read == DecodeOptionSymbol4(EncodeOptionSymbol4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDepthLevel ==
    \A message \in CheckedMarketDepthLevel :
        LET read == DecodeMarketDepthLevel(EncodeMarketDepthLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionMarketDepthMessage ==
    \A message \in CheckedOptionMarketDepthMessage :
        LET read == DecodeOptionMarketDepthMessage(EncodeOptionMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol5 ==
    \A message \in CheckedFutureOptionSymbol5 :
        LET read == DecodeFutureOptionSymbol5(EncodeFutureOptionSymbol5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsMarketDepthLevel ==
    \A message \in CheckedFutureOptionsMarketDepthLevel :
        LET read == DecodeFutureOptionsMarketDepthLevel(EncodeFutureOptionsMarketDepthLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsMarketDepthMessage ==
    \A message \in CheckedFutureOptionsMarketDepthMessage :
        LET read == DecodeFutureOptionsMarketDepthMessage(EncodeFutureOptionsMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct5 ==
    \A message \in CheckedFutureProduct5 :
        LET read == DecodeFutureProduct5(EncodeFutureProduct5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesMarketDepthLevel ==
    \A message \in CheckedFuturesMarketDepthLevel :
        LET read == DecodeFuturesMarketDepthLevel(EncodeFuturesMarketDepthLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesMarketDepthMessage ==
    \A message \in CheckedFuturesMarketDepthMessage :
        LET read == DecodeFuturesMarketDepthMessage(EncodeFuturesMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Market Depth Level decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyMarketDepthLevel ==
    \A message \in CheckedStrategyMarketDepthLevel :
        LET read == DecodeStrategyMarketDepthLevel(EncodeStrategyMarketDepthLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Market Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyMarketDepthMessage ==
    \A message \in CheckedStrategyMarketDepthMessage :
        LET read == DecodeStrategyMarketDepthMessage(EncodeStrategyMarketDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol5 ==
    \A message \in CheckedOptionSymbol5 :
        LET read == DecodeOptionSymbol5(EncodeOptionSymbol5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionTradeCancellationMessage ==
    \A message \in CheckedOptionTradeCancellationMessage :
        LET read == DecodeOptionTradeCancellationMessage(EncodeOptionTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol6 ==
    \A message \in CheckedFutureOptionSymbol6 :
        LET read == DecodeFutureOptionSymbol6(EncodeFutureOptionSymbol6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsTradeCancellationMessage ==
    \A message \in CheckedFutureOptionsTradeCancellationMessage :
        LET read == DecodeFutureOptionsTradeCancellationMessage(EncodeFutureOptionsTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct6 ==
    \A message \in CheckedFutureProduct6 :
        LET read == DecodeFutureProduct6(EncodeFutureProduct6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureTradeCancellationMessage ==
    \A message \in CheckedFutureTradeCancellationMessage :
        LET read == DecodeFutureTradeCancellationMessage(EncodeFutureTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyTradeCancellationMessage ==
    \A message \in CheckedStrategyTradeCancellationMessage :
        LET read == DecodeStrategyTradeCancellationMessage(EncodeStrategyTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol6 ==
    \A message \in CheckedOptionSymbol6 :
        LET read == DecodeOptionSymbol6(EncodeOptionSymbol6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionInstrumentKeysMessage ==
    \A message \in CheckedOptionInstrumentKeysMessage :
        LET read == DecodeOptionInstrumentKeysMessage(EncodeOptionInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol7 ==
    \A message \in CheckedFutureOptionSymbol7 :
        LET read == DecodeFutureOptionSymbol7(EncodeFutureOptionSymbol7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsInstrumentKeysMessage ==
    \A message \in CheckedFutureOptionsInstrumentKeysMessage :
        LET read == DecodeFutureOptionsInstrumentKeysMessage(EncodeFutureOptionsInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingInstrumentKeysMessage ==
    \A message \in CheckedUnderlyingInstrumentKeysMessage :
        LET read == DecodeUnderlyingInstrumentKeysMessage(EncodeUnderlyingInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct7 ==
    \A message \in CheckedFutureProduct7 :
        LET read == DecodeFutureProduct7(EncodeFutureProduct7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Associated Product decodes back to what was encoded, and leaves nothing over *)
RoundTripAssociatedProduct ==
    \A message \in CheckedAssociatedProduct :
        LET read == DecodeAssociatedProduct(EncodeAssociatedProduct(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesInstrumentKeysMessage ==
    \A message \in CheckedFuturesInstrumentKeysMessage :
        LET read == DecodeFuturesInstrumentKeysMessage(EncodeFuturesInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Instrument Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyInstrumentLeg ==
    \A message \in CheckedStrategyInstrumentLeg :
        LET read == DecodeStrategyInstrumentLeg(EncodeStrategyInstrumentLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Instrument Keys Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyInstrumentKeysMessage ==
    \A message \in CheckedStrategyInstrumentKeysMessage :
        LET read == DecodeStrategyInstrumentKeysMessage(EncodeStrategyInstrumentKeysMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol7 ==
    \A message \in CheckedOptionSymbol7 :
        LET read == DecodeOptionSymbol7(EncodeOptionSymbol7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Auction Beginning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionAuctionBeginningMessage ==
    \A message \in CheckedOptionAuctionBeginningMessage :
        LET read == DecodeOptionAuctionBeginningMessage(EncodeOptionAuctionBeginningMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Auction Beginning Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyAuctionBeginningMessage ==
    \A message \in CheckedStrategyAuctionBeginningMessage :
        LET read == DecodeStrategyAuctionBeginningMessage(EncodeStrategyAuctionBeginningMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol8 ==
    \A message \in CheckedOptionSymbol8 :
        LET read == DecodeOptionSymbol8(EncodeOptionSymbol8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSummaryMessage ==
    \A message \in CheckedOptionSummaryMessage :
        LET read == DecodeOptionSummaryMessage(EncodeOptionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionSymbol8 ==
    \A message \in CheckedFutureOptionSymbol8 :
        LET read == DecodeFutureOptionSymbol8(EncodeFutureOptionSymbol8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureOptionsSummaryMessage ==
    \A message \in CheckedFutureOptionsSummaryMessage :
        LET read == DecodeFutureOptionsSummaryMessage(EncodeFutureOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct8 ==
    \A message \in CheckedFutureProduct8 :
        LET read == DecodeFutureProduct8(EncodeFutureProduct8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesSummaryMessage ==
    \A message \in CheckedFuturesSummaryMessage :
        LET read == DecodeFuturesSummaryMessage(EncodeFuturesSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategySummaryMessage ==
    \A message \in CheckedStrategySummaryMessage :
        LET read == DecodeStrategySummaryMessage(EncodeStrategySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol9 ==
    \A message \in CheckedOptionSymbol9 :
        LET read == DecodeOptionSymbol9(EncodeOptionSymbol9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Initial And Improvement Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionInitialAndImprovementOrderMessage ==
    \A message \in CheckedOptionInitialAndImprovementOrderMessage :
        LET read == DecodeOptionInitialAndImprovementOrderMessage(EncodeOptionInitialAndImprovementOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Initial And Improvement Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyInitialAndImprovementOrderMessage ==
    \A message \in CheckedStrategyInitialAndImprovementOrderMessage :
        LET read == DecodeStrategyInitialAndImprovementOrderMessage(EncodeStrategyInitialAndImprovementOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfOptionsSummaryMessage ==
    \A message \in CheckedBeginningOfOptionsSummaryMessage :
        LET read == DecodeBeginningOfOptionsSummaryMessage(EncodeBeginningOfOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Future Options Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfFutureOptionsSummaryMessage ==
    \A message \in CheckedBeginningOfFutureOptionsSummaryMessage :
        LET read == DecodeBeginningOfFutureOptionsSummaryMessage(EncodeBeginningOfFutureOptionsSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Futures Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfFuturesSummaryMessage ==
    \A message \in CheckedBeginningOfFuturesSummaryMessage :
        LET read == DecodeBeginningOfFuturesSummaryMessage(EncodeBeginningOfFuturesSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Beginning Of Strategy Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBeginningOfStrategySummaryMessage ==
    \A message \in CheckedBeginningOfStrategySummaryMessage :
        LET read == DecodeBeginningOfStrategySummaryMessage(EncodeBeginningOfStrategySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionSymbol10 ==
    \A message \in CheckedOptionSymbol10 :
        LET read == DecodeOptionSymbol10(EncodeOptionSymbol10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Option Auction Ending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionAuctionEndingMessage ==
    \A message \in CheckedOptionAuctionEndingMessage :
        LET read == DecodeOptionAuctionEndingMessage(EncodeOptionAuctionEndingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Auction Ending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyAuctionEndingMessage ==
    \A message \in CheckedStrategyAuctionEndingMessage :
        LET read == DecodeStrategyAuctionEndingMessage(EncodeStrategyAuctionEndingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct9 ==
    \A message \in CheckedFutureProduct9 :
        LET read == DecodeFutureProduct9(EncodeFutureProduct9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Futures Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFuturesTradeCorrectionMessage ==
    \A message \in CheckedFuturesTradeCorrectionMessage :
        LET read == DecodeFuturesTradeCorrectionMessage(EncodeFuturesTradeCorrectionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupStatusMessage ==
    \A message \in CheckedGroupStatusMessage :
        LET read == DecodeGroupStatusMessage(EncodeGroupStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Group Status Strategies Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGroupStatusStrategiesMessage ==
    \A message \in CheckedGroupStatusStrategiesMessage :
        LET read == DecodeGroupStatusStrategiesMessage(EncodeGroupStatusStrategiesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Product decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureProduct10 ==
    \A message \in CheckedFutureProduct10 :
        LET read == DecodeFutureProduct10(EncodeFutureProduct10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bond Definition decodes back to what was encoded, and leaves nothing over *)
RoundTripBondDefinition ==
    \A message \in CheckedBondDefinition :
        LET read == DecodeBondDefinition(EncodeBondDefinition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Future Deliverables Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFutureDeliverablesMessage ==
    \A message \in CheckedFutureDeliverablesMessage :
        LET read == DecodeFutureDeliverablesMessage(EncodeFutureDeliverablesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Regular Text Bulletin decodes back to what was encoded, and leaves nothing over *)
RoundTripRegularTextBulletin ==
    \A message \in CheckedRegularTextBulletin :
        LET read == DecodeRegularTextBulletin(EncodeRegularTextBulletin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Text Bulletin decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialTextBulletin ==
    \A message \in CheckedSpecialTextBulletin :
        LET read == DecodeSpecialTextBulletin(EncodeSpecialTextBulletin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bulletins Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBulletinsMessage ==
    \A message \in CheckedBulletinsMessage :
        LET read == DecodeBulletinsMessage(EncodeBulletinsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Sales Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSalesMessage ==
    \A message \in CheckedEndOfSalesMessage :
        LET read == DecodeEndOfSalesMessage(EncodeEndOfSalesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTickEntry ==
    \A message \in CheckedTickEntry :
        LET read == DecodeTickEntry(EncodeTickEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Table Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickTableMessage ==
    \A message \in CheckedTickTableMessage :
        LET read == DecodeTickTableMessage(EncodeTickTableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Transmission Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfTransmissionMessage ==
    \A message \in CheckedEndOfTransmissionMessage :
        LET read == DecodeEndOfTransmissionMessage(EncodeEndOfTransmissionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Circuit Assurance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCircuitAssuranceMessage ==
    \A message \in CheckedCircuitAssuranceMessage :
        LET read == DecodeCircuitAssuranceMessage(EncodeCircuitAssuranceMessage(message))
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

(* Every Sola Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripSolaFrame ==
    \A message \in CheckedSolaFrame :
        LET read == DecodeSolaFrame(EncodeSolaFrame(message))
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

(* A Bulletin is selected by the Bulletin Type it is written under *)
SelectsBulletin ==
    \A message \in CheckedBulletin :
        LET sent == EncodeBulletin(message)
            read == DecodeBulletin(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET sent == EncodeMessageBody(message)
            read == DecodeMessageBody(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
