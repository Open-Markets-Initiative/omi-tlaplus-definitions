------------------- MODULE C1Options_OpeningAuction_v1_0 -------------------
(***************************************************************************)
(* Chicago Board Options Exchange Opening Auction Feed v1.0                *)
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
(* Security Type                                                           *)
(***************************************************************************)

SecurityType ==
    [ securityTypeText : SampleBytes ]

EncodeSecurityType(message) ==
    EncodeUIntBE(Len(message.securityTypeText), 1)
        \o message.securityTypeText

DecodeSecurityType(bytes) ==
    LET securityTypeLength == ReadUIntBE(bytes, 1) IN IF ~securityTypeLength.ok THEN Fail ELSE
    LET securityTypeText == ReadBytes(securityTypeLength.rest, securityTypeLength.value) IN IF ~securityTypeText.ok THEN Fail ELSE
    Ok([ securityTypeText |-> securityTypeText.value ], securityTypeText.rest)

ZeroSecurityType ==
    [ securityTypeText |-> << >> ]

(* Security Type at zero, then each field in turn at the values it is checked at *)
CheckedSecurityType ==
    { ZeroSecurityType }
        \cup { [ZeroSecurityType EXCEPT !.securityTypeText = one] : one \in SampleBytes }

(***************************************************************************)
(* Symbol                                                                  *)
(***************************************************************************)

Symbol ==
    [ symbolText : SampleBytes ]

EncodeSymbol(message) ==
    EncodeUIntBE(Len(message.symbolText), 1)
        \o message.symbolText

DecodeSymbol(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolText == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolText.ok THEN Fail ELSE
    Ok([ symbolText |-> symbolText.value ], symbolText.rest)

ZeroSymbol ==
    [ symbolText |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol ==
    { ZeroSymbol }
        \cup { [ZeroSymbol EXCEPT !.symbolText = one] : one \in SampleBytes }

(***************************************************************************)
(* Target Location Id                                                      *)
(***************************************************************************)

TargetLocationId ==
    [ targetLocationIdText : SampleBytes ]

EncodeTargetLocationId(message) ==
    EncodeUIntBE(Len(message.targetLocationIdText), 1)
        \o message.targetLocationIdText

DecodeTargetLocationId(bytes) ==
    LET targetLocationIdLength == ReadUIntBE(bytes, 1) IN IF ~targetLocationIdLength.ok THEN Fail ELSE
    LET targetLocationIdText == ReadBytes(targetLocationIdLength.rest, targetLocationIdLength.value) IN IF ~targetLocationIdText.ok THEN Fail ELSE
    Ok([ targetLocationIdText |-> targetLocationIdText.value ], targetLocationIdText.rest)

ZeroTargetLocationId ==
    [ targetLocationIdText |-> << >> ]

(* Target Location Id at zero, then each field in turn at the values it is checked at *)
CheckedTargetLocationId ==
    { ZeroTargetLocationId }
        \cup { [ZeroTargetLocationId EXCEPT !.targetLocationIdText = one] : one \in SampleBytes }

(***************************************************************************)
(* Strike Price: 5 bytes                                                   *)
(***************************************************************************)

StrikePrice ==
    [ strikePriceExponent : Sample(1),
      strikePriceMantissa : Sample(4) ]

EncodeStrikePrice(message) ==
    message.strikePriceExponent
        \o message.strikePriceMantissa

DecodeStrikePrice(bytes) ==
    LET strikePriceExponent == ReadBytes(bytes, 1) IN IF ~strikePriceExponent.ok THEN Fail ELSE
    LET strikePriceMantissa == ReadBytes(strikePriceExponent.rest, 4) IN IF ~strikePriceMantissa.ok THEN Fail ELSE
    Ok([ strikePriceExponent |-> strikePriceExponent.value,
         strikePriceMantissa |-> strikePriceMantissa.value ], strikePriceMantissa.rest)

ZeroStrikePrice ==
    [ strikePriceExponent |-> [i \in 1 .. 1 |-> 0],
      strikePriceMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Strike Price at zero, then each field in turn at the values it is checked at *)
CheckedStrikePrice ==
    { ZeroStrikePrice }
        \cup { [ZeroStrikePrice EXCEPT !.strikePriceExponent = one] : one \in Sample(1) }
        \cup { [ZeroStrikePrice EXCEPT !.strikePriceMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Minimum Strike Price Fraction: 5 bytes                                  *)
(***************************************************************************)

MinimumStrikePriceFraction ==
    [ minimumStrikePriceFractionExponent : Sample(1),
      minimumStrikePriceFractionMantissa : Sample(4) ]

EncodeMinimumStrikePriceFraction(message) ==
    message.minimumStrikePriceFractionExponent
        \o message.minimumStrikePriceFractionMantissa

DecodeMinimumStrikePriceFraction(bytes) ==
    LET minimumStrikePriceFractionExponent == ReadBytes(bytes, 1) IN IF ~minimumStrikePriceFractionExponent.ok THEN Fail ELSE
    LET minimumStrikePriceFractionMantissa == ReadBytes(minimumStrikePriceFractionExponent.rest, 4) IN IF ~minimumStrikePriceFractionMantissa.ok THEN Fail ELSE
    Ok([ minimumStrikePriceFractionExponent |-> minimumStrikePriceFractionExponent.value,
         minimumStrikePriceFractionMantissa |-> minimumStrikePriceFractionMantissa.value ], minimumStrikePriceFractionMantissa.rest)

ZeroMinimumStrikePriceFraction ==
    [ minimumStrikePriceFractionExponent |-> [i \in 1 .. 1 |-> 0],
      minimumStrikePriceFractionMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Minimum Strike Price Fraction at zero, then each field in turn at the values it is checked at *)
CheckedMinimumStrikePriceFraction ==
    { ZeroMinimumStrikePriceFraction }
        \cup { [ZeroMinimumStrikePriceFraction EXCEPT !.minimumStrikePriceFractionExponent = one] : one \in Sample(1) }
        \cup { [ZeroMinimumStrikePriceFraction EXCEPT !.minimumStrikePriceFractionMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Max Strike Price: 5 bytes                                               *)
(***************************************************************************)

MaxStrikePrice ==
    [ maxStrikePriceExponent : Sample(1),
      maxStrikePriceMantissa : Sample(4) ]

EncodeMaxStrikePrice(message) ==
    message.maxStrikePriceExponent
        \o message.maxStrikePriceMantissa

DecodeMaxStrikePrice(bytes) ==
    LET maxStrikePriceExponent == ReadBytes(bytes, 1) IN IF ~maxStrikePriceExponent.ok THEN Fail ELSE
    LET maxStrikePriceMantissa == ReadBytes(maxStrikePriceExponent.rest, 4) IN IF ~maxStrikePriceMantissa.ok THEN Fail ELSE
    Ok([ maxStrikePriceExponent |-> maxStrikePriceExponent.value,
         maxStrikePriceMantissa |-> maxStrikePriceMantissa.value ], maxStrikePriceMantissa.rest)

ZeroMaxStrikePrice ==
    [ maxStrikePriceExponent |-> [i \in 1 .. 1 |-> 0],
      maxStrikePriceMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Max Strike Price at zero, then each field in turn at the values it is checked at *)
CheckedMaxStrikePrice ==
    { ZeroMaxStrikePrice }
        \cup { [ZeroMaxStrikePrice EXCEPT !.maxStrikePriceExponent = one] : one \in Sample(1) }
        \cup { [ZeroMaxStrikePrice EXCEPT !.maxStrikePriceMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Premium Break Point: 5 bytes                                            *)
(***************************************************************************)

PremiumBreakPoint ==
    [ premiumBreakPointExponent : Sample(1),
      premiumBreakPointMantissa : Sample(4) ]

EncodePremiumBreakPoint(message) ==
    message.premiumBreakPointExponent
        \o message.premiumBreakPointMantissa

DecodePremiumBreakPoint(bytes) ==
    LET premiumBreakPointExponent == ReadBytes(bytes, 1) IN IF ~premiumBreakPointExponent.ok THEN Fail ELSE
    LET premiumBreakPointMantissa == ReadBytes(premiumBreakPointExponent.rest, 4) IN IF ~premiumBreakPointMantissa.ok THEN Fail ELSE
    Ok([ premiumBreakPointExponent |-> premiumBreakPointExponent.value,
         premiumBreakPointMantissa |-> premiumBreakPointMantissa.value ], premiumBreakPointMantissa.rest)

ZeroPremiumBreakPoint ==
    [ premiumBreakPointExponent |-> [i \in 1 .. 1 |-> 0],
      premiumBreakPointMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Premium Break Point at zero, then each field in turn at the values it is checked at *)
CheckedPremiumBreakPoint ==
    { ZeroPremiumBreakPoint }
        \cup { [ZeroPremiumBreakPoint EXCEPT !.premiumBreakPointExponent = one] : one \in Sample(1) }
        \cup { [ZeroPremiumBreakPoint EXCEPT !.premiumBreakPointMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Minimum Above Premium Fraction: 5 bytes                                 *)
(***************************************************************************)

MinimumAbovePremiumFraction ==
    [ minimumAbovePremiumFractionExponent : Sample(1),
      minimumAbovePremiumFractionMantissa : Sample(4) ]

EncodeMinimumAbovePremiumFraction(message) ==
    message.minimumAbovePremiumFractionExponent
        \o message.minimumAbovePremiumFractionMantissa

DecodeMinimumAbovePremiumFraction(bytes) ==
    LET minimumAbovePremiumFractionExponent == ReadBytes(bytes, 1) IN IF ~minimumAbovePremiumFractionExponent.ok THEN Fail ELSE
    LET minimumAbovePremiumFractionMantissa == ReadBytes(minimumAbovePremiumFractionExponent.rest, 4) IN IF ~minimumAbovePremiumFractionMantissa.ok THEN Fail ELSE
    Ok([ minimumAbovePremiumFractionExponent |-> minimumAbovePremiumFractionExponent.value,
         minimumAbovePremiumFractionMantissa |-> minimumAbovePremiumFractionMantissa.value ], minimumAbovePremiumFractionMantissa.rest)

ZeroMinimumAbovePremiumFraction ==
    [ minimumAbovePremiumFractionExponent |-> [i \in 1 .. 1 |-> 0],
      minimumAbovePremiumFractionMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Minimum Above Premium Fraction at zero, then each field in turn at the values it is checked at *)
CheckedMinimumAbovePremiumFraction ==
    { ZeroMinimumAbovePremiumFraction }
        \cup { [ZeroMinimumAbovePremiumFraction EXCEPT !.minimumAbovePremiumFractionExponent = one] : one \in Sample(1) }
        \cup { [ZeroMinimumAbovePremiumFraction EXCEPT !.minimumAbovePremiumFractionMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Minimum Below Premium Fraction: 5 bytes                                 *)
(***************************************************************************)

MinimumBelowPremiumFraction ==
    [ minimumBelowPremiumFractionExponent : Sample(1),
      minimumBelowPremiumFractionMantissa : Sample(4) ]

EncodeMinimumBelowPremiumFraction(message) ==
    message.minimumBelowPremiumFractionExponent
        \o message.minimumBelowPremiumFractionMantissa

DecodeMinimumBelowPremiumFraction(bytes) ==
    LET minimumBelowPremiumFractionExponent == ReadBytes(bytes, 1) IN IF ~minimumBelowPremiumFractionExponent.ok THEN Fail ELSE
    LET minimumBelowPremiumFractionMantissa == ReadBytes(minimumBelowPremiumFractionExponent.rest, 4) IN IF ~minimumBelowPremiumFractionMantissa.ok THEN Fail ELSE
    Ok([ minimumBelowPremiumFractionExponent |-> minimumBelowPremiumFractionExponent.value,
         minimumBelowPremiumFractionMantissa |-> minimumBelowPremiumFractionMantissa.value ], minimumBelowPremiumFractionMantissa.rest)

ZeroMinimumBelowPremiumFraction ==
    [ minimumBelowPremiumFractionExponent |-> [i \in 1 .. 1 |-> 0],
      minimumBelowPremiumFractionMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Minimum Below Premium Fraction at zero, then each field in turn at the values it is checked at *)
CheckedMinimumBelowPremiumFraction ==
    { ZeroMinimumBelowPremiumFraction }
        \cup { [ZeroMinimumBelowPremiumFraction EXCEPT !.minimumBelowPremiumFractionExponent = one] : one \in Sample(1) }
        \cup { [ZeroMinimumBelowPremiumFraction EXCEPT !.minimumBelowPremiumFractionMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Currency Code                                                           *)
(***************************************************************************)

CurrencyCode ==
    [ currencyCodeText : SampleBytes ]

EncodeCurrencyCode(message) ==
    EncodeUIntBE(Len(message.currencyCodeText), 1)
        \o message.currencyCodeText

DecodeCurrencyCode(bytes) ==
    LET currencyCodeLength == ReadUIntBE(bytes, 1) IN IF ~currencyCodeLength.ok THEN Fail ELSE
    LET currencyCodeText == ReadBytes(currencyCodeLength.rest, currencyCodeLength.value) IN IF ~currencyCodeText.ok THEN Fail ELSE
    Ok([ currencyCodeText |-> currencyCodeText.value ], currencyCodeText.rest)

ZeroCurrencyCode ==
    [ currencyCodeText |-> << >> ]

(* Currency Code at zero, then each field in turn at the values it is checked at *)
CheckedCurrencyCode ==
    { ZeroCurrencyCode }
        \cup { [ZeroCurrencyCode EXCEPT !.currencyCodeText = one] : one \in SampleBytes }

(***************************************************************************)
(* Underlying Symbol                                                       *)
(***************************************************************************)

UnderlyingSymbol ==
    [ underlyingSymbolText : SampleBytes ]

EncodeUnderlyingSymbol(message) ==
    EncodeUIntBE(Len(message.underlyingSymbolText), 1)
        \o message.underlyingSymbolText

DecodeUnderlyingSymbol(bytes) ==
    LET underlyingSymbolLength == ReadUIntBE(bytes, 1) IN IF ~underlyingSymbolLength.ok THEN Fail ELSE
    LET underlyingSymbolText == ReadBytes(underlyingSymbolLength.rest, underlyingSymbolLength.value) IN IF ~underlyingSymbolText.ok THEN Fail ELSE
    Ok([ underlyingSymbolText |-> underlyingSymbolText.value ], underlyingSymbolText.rest)

ZeroUnderlyingSymbol ==
    [ underlyingSymbolText |-> << >> ]

(* Underlying Symbol at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingSymbol ==
    { ZeroUnderlyingSymbol }
        \cup { [ZeroUnderlyingSymbol EXCEPT !.underlyingSymbolText = one] : one \in SampleBytes }

(***************************************************************************)
(* Underlying Type                                                         *)
(***************************************************************************)

UnderlyingType ==
    [ underlyingTypeText : SampleBytes ]

EncodeUnderlyingType(message) ==
    EncodeUIntBE(Len(message.underlyingTypeText), 1)
        \o message.underlyingTypeText

DecodeUnderlyingType(bytes) ==
    LET underlyingTypeLength == ReadUIntBE(bytes, 1) IN IF ~underlyingTypeLength.ok THEN Fail ELSE
    LET underlyingTypeText == ReadBytes(underlyingTypeLength.rest, underlyingTypeLength.value) IN IF ~underlyingTypeText.ok THEN Fail ELSE
    Ok([ underlyingTypeText |-> underlyingTypeText.value ], underlyingTypeText.rest)

ZeroUnderlyingType ==
    [ underlyingTypeText |-> << >> ]

(* Underlying Type at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingType ==
    { ZeroUnderlyingType }
        \cup { [ZeroUnderlyingType EXCEPT !.underlyingTypeText = one] : one \in SampleBytes }

(***************************************************************************)
(* Security Definition Leg: 9 bytes                                        *)
(***************************************************************************)

SecurityDefinitionLeg ==
    [ legRatioQty   : Sample(4),
      legSecurityId : Sample(4),
      legSide       : Sample(1) ]

EncodeSecurityDefinitionLeg(message) ==
    message.legRatioQty
        \o message.legSecurityId
        \o message.legSide

DecodeSecurityDefinitionLeg(bytes) ==
    LET legRatioQty == ReadBytes(bytes, 4) IN IF ~legRatioQty.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legRatioQty.rest, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSecurityId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legRatioQty   |-> legRatioQty.value,
         legSecurityId |-> legSecurityId.value,
         legSide       |-> legSide.value ], legSide.rest)

ZeroSecurityDefinitionLeg ==
    [ legRatioQty   |-> [i \in 1 .. 4 |-> 0],
      legSecurityId |-> [i \in 1 .. 4 |-> 0],
      legSide       |-> [i \in 1 .. 1 |-> 0] ]

(* Security Definition Leg at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionLeg ==
    { ZeroSecurityDefinitionLeg }
        \cup { [ZeroSecurityDefinitionLeg EXCEPT !.legRatioQty = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionLeg EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionLeg EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Security Definition Leg, written one after another *)
RECURSIVE EncodeSecurityDefinitionLegList(_)
EncodeSecurityDefinitionLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityDefinitionLeg(Head(messages)) \o EncodeSecurityDefinitionLegList(Tail(messages))

(* As many Security Definition Leg as the field that counts them says *)
RECURSIVE ReadSecurityDefinitionLegList(_, _)
ReadSecurityDefinitionLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityDefinitionLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityDefinitionLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Definition Leg of each kind, for the lists that carry them *)
OneSecurityDefinitionLeg == { ZeroSecurityDefinitionLeg }

(***************************************************************************)
(* Security Definition Message                                             *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityType                : SecurityType,
      securityExchange            : Sample(1),
      symbol                      : Symbol,
      targetLocationId            : TargetLocationId,
      classKey                    : Sample(4),
      securityId                  : Sample(4),
      maturityDate                : Sample(8),
      priceType                   : Sample(1),
      strikePrice                 : StrikePrice,
      putOrCall                   : Sample(1),
      minimumStrikePriceFraction  : MinimumStrikePriceFraction,
      maxStrikePrice              : MaxStrikePrice,
      premiumBreakPoint           : PremiumBreakPoint,
      minimumAbovePremiumFraction : MinimumAbovePremiumFraction,
      minimumBelowPremiumFraction : MinimumBelowPremiumFraction,
      exerciseStyle               : Sample(1),
      currencyCode                : CurrencyCode,
      underlyingSymbol            : UnderlyingSymbol,
      underlyingType              : UnderlyingType,
      contractSize                : Sample(4),
      securityDefinitionLeg       : SampleLists(OneSecurityDefinitionLeg) ]

EncodeSecurityDefinitionMessage(message) ==
    EncodeSecurityType(message.securityType)
        \o message.securityExchange
        \o EncodeSymbol(message.symbol)
        \o EncodeTargetLocationId(message.targetLocationId)
        \o message.classKey
        \o message.securityId
        \o message.maturityDate
        \o message.priceType
        \o EncodeStrikePrice(message.strikePrice)
        \o message.putOrCall
        \o EncodeMinimumStrikePriceFraction(message.minimumStrikePriceFraction)
        \o EncodeMaxStrikePrice(message.maxStrikePrice)
        \o EncodePremiumBreakPoint(message.premiumBreakPoint)
        \o EncodeMinimumAbovePremiumFraction(message.minimumAbovePremiumFraction)
        \o EncodeMinimumBelowPremiumFraction(message.minimumBelowPremiumFraction)
        \o message.exerciseStyle
        \o EncodeCurrencyCode(message.currencyCode)
        \o EncodeUnderlyingSymbol(message.underlyingSymbol)
        \o EncodeUnderlyingType(message.underlyingType)
        \o message.contractSize
        \o EncodeUIntBE(Len(message.securityDefinitionLeg), 1)
        \o EncodeSecurityDefinitionLegList(message.securityDefinitionLeg)

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityType == DecodeSecurityType(bytes) IN IF ~securityType.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(securityType.rest, 1) IN IF ~securityExchange.ok THEN Fail ELSE
    LET symbol == DecodeSymbol(securityExchange.rest) IN IF ~symbol.ok THEN Fail ELSE
    LET targetLocationId == DecodeTargetLocationId(symbol.rest) IN IF ~targetLocationId.ok THEN Fail ELSE
    LET classKey == ReadBytes(targetLocationId.rest, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityId.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET priceType == ReadBytes(maturityDate.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET strikePrice == DecodeStrikePrice(priceType.rest) IN IF ~strikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(strikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET minimumStrikePriceFraction == DecodeMinimumStrikePriceFraction(putOrCall.rest) IN IF ~minimumStrikePriceFraction.ok THEN Fail ELSE
    LET maxStrikePrice == DecodeMaxStrikePrice(minimumStrikePriceFraction.rest) IN IF ~maxStrikePrice.ok THEN Fail ELSE
    LET premiumBreakPoint == DecodePremiumBreakPoint(maxStrikePrice.rest) IN IF ~premiumBreakPoint.ok THEN Fail ELSE
    LET minimumAbovePremiumFraction == DecodeMinimumAbovePremiumFraction(premiumBreakPoint.rest) IN IF ~minimumAbovePremiumFraction.ok THEN Fail ELSE
    LET minimumBelowPremiumFraction == DecodeMinimumBelowPremiumFraction(minimumAbovePremiumFraction.rest) IN IF ~minimumBelowPremiumFraction.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(minimumBelowPremiumFraction.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET currencyCode == DecodeCurrencyCode(exerciseStyle.rest) IN IF ~currencyCode.ok THEN Fail ELSE
    LET underlyingSymbol == DecodeUnderlyingSymbol(currencyCode.rest) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingType == DecodeUnderlyingType(underlyingSymbol.rest) IN IF ~underlyingType.ok THEN Fail ELSE
    LET contractSize == ReadBytes(underlyingType.rest, 4) IN IF ~contractSize.ok THEN Fail ELSE
    LET noLegs == ReadUIntBE(contractSize.rest, 1) IN IF ~noLegs.ok THEN Fail ELSE
    LET securityDefinitionLeg == ReadSecurityDefinitionLegList(noLegs.rest, noLegs.value) IN IF ~securityDefinitionLeg.ok THEN Fail ELSE
    Ok([ securityType                |-> securityType.value,
         securityExchange            |-> securityExchange.value,
         symbol                      |-> symbol.value,
         targetLocationId            |-> targetLocationId.value,
         classKey                    |-> classKey.value,
         securityId                  |-> securityId.value,
         maturityDate                |-> maturityDate.value,
         priceType                   |-> priceType.value,
         strikePrice                 |-> strikePrice.value,
         putOrCall                   |-> putOrCall.value,
         minimumStrikePriceFraction  |-> minimumStrikePriceFraction.value,
         maxStrikePrice              |-> maxStrikePrice.value,
         premiumBreakPoint           |-> premiumBreakPoint.value,
         minimumAbovePremiumFraction |-> minimumAbovePremiumFraction.value,
         minimumBelowPremiumFraction |-> minimumBelowPremiumFraction.value,
         exerciseStyle               |-> exerciseStyle.value,
         currencyCode                |-> currencyCode.value,
         underlyingSymbol            |-> underlyingSymbol.value,
         underlyingType              |-> underlyingType.value,
         contractSize                |-> contractSize.value,
         securityDefinitionLeg       |-> securityDefinitionLeg.value ], securityDefinitionLeg.rest)

ZeroSecurityDefinitionMessage ==
    [ securityType                |-> ZeroSecurityType,
      securityExchange            |-> [i \in 1 .. 1 |-> 0],
      symbol                      |-> ZeroSymbol,
      targetLocationId            |-> ZeroTargetLocationId,
      classKey                    |-> [i \in 1 .. 4 |-> 0],
      securityId                  |-> [i \in 1 .. 4 |-> 0],
      maturityDate                |-> [i \in 1 .. 8 |-> 0],
      priceType                   |-> [i \in 1 .. 1 |-> 0],
      strikePrice                 |-> ZeroStrikePrice,
      putOrCall                   |-> [i \in 1 .. 1 |-> 0],
      minimumStrikePriceFraction  |-> ZeroMinimumStrikePriceFraction,
      maxStrikePrice              |-> ZeroMaxStrikePrice,
      premiumBreakPoint           |-> ZeroPremiumBreakPoint,
      minimumAbovePremiumFraction |-> ZeroMinimumAbovePremiumFraction,
      minimumBelowPremiumFraction |-> ZeroMinimumBelowPremiumFraction,
      exerciseStyle               |-> [i \in 1 .. 1 |-> 0],
      currencyCode                |-> ZeroCurrencyCode,
      underlyingSymbol            |-> ZeroUnderlyingSymbol,
      underlyingType              |-> ZeroUnderlyingType,
      contractSize                |-> [i \in 1 .. 4 |-> 0],
      securityDefinitionLeg       |-> << >> ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityType = one] : one \in CheckedSecurityType }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityExchange = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.symbol = one] : one \in CheckedSymbol }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.targetLocationId = one] : one \in CheckedTargetLocationId }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.strikePrice = one] : one \in CheckedStrikePrice }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minimumStrikePriceFraction = one] : one \in CheckedMinimumStrikePriceFraction }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.maxStrikePrice = one] : one \in CheckedMaxStrikePrice }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.premiumBreakPoint = one] : one \in CheckedPremiumBreakPoint }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minimumAbovePremiumFraction = one] : one \in CheckedMinimumAbovePremiumFraction }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.minimumBelowPremiumFraction = one] : one \in CheckedMinimumBelowPremiumFraction }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currencyCode = one] : one \in CheckedCurrencyCode }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.underlyingSymbol = one] : one \in CheckedUnderlyingSymbol }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.underlyingType = one] : one \in CheckedUnderlyingType }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.contractSize = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionLeg = one] : one \in SampleLists(OneSecurityDefinitionLeg) }

(***************************************************************************)
(* Prev Close Px: 5 bytes                                                  *)
(***************************************************************************)

PrevClosePx ==
    [ prevClosePxExponent : Sample(1),
      prevClosePxMantissa : Sample(4) ]

EncodePrevClosePx(message) ==
    message.prevClosePxExponent
        \o message.prevClosePxMantissa

DecodePrevClosePx(bytes) ==
    LET prevClosePxExponent == ReadBytes(bytes, 1) IN IF ~prevClosePxExponent.ok THEN Fail ELSE
    LET prevClosePxMantissa == ReadBytes(prevClosePxExponent.rest, 4) IN IF ~prevClosePxMantissa.ok THEN Fail ELSE
    Ok([ prevClosePxExponent |-> prevClosePxExponent.value,
         prevClosePxMantissa |-> prevClosePxMantissa.value ], prevClosePxMantissa.rest)

ZeroPrevClosePx ==
    [ prevClosePxExponent |-> [i \in 1 .. 1 |-> 0],
      prevClosePxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Prev Close Px at zero, then each field in turn at the values it is checked at *)
CheckedPrevClosePx ==
    { ZeroPrevClosePx }
        \cup { [ZeroPrevClosePx EXCEPT !.prevClosePxExponent = one] : one \in Sample(1) }
        \cup { [ZeroPrevClosePx EXCEPT !.prevClosePxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx ==
    { ZeroMdEntryPx }
        \cup { [ZeroMdEntryPx EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entry: 11 bytes                                                      *)
(***************************************************************************)

MdEntry ==
    [ mdEntryType  : Sample(1),
      mdEntryPx    : MdEntryPx,
      mdEntrySize  : Sample(4),
      mdVolumeType : Sample(1) ]

EncodeMdEntry(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx(message.mdEntryPx)
        \o message.mdEntrySize
        \o message.mdVolumeType

DecodeMdEntry(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 4) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdVolumeType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdVolumeType.ok THEN Fail ELSE
    Ok([ mdEntryType  |-> mdEntryType.value,
         mdEntryPx    |-> mdEntryPx.value,
         mdEntrySize  |-> mdEntrySize.value,
         mdVolumeType |-> mdVolumeType.value ], mdVolumeType.rest)

ZeroMdEntry ==
    [ mdEntryType  |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx    |-> ZeroMdEntryPx,
      mdEntrySize  |-> [i \in 1 .. 4 |-> 0],
      mdVolumeType |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedMdEntry ==
    { ZeroMdEntry }
        \cup { [ZeroMdEntry EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntry EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx }
        \cup { [ZeroMdEntry EXCEPT !.mdEntrySize = one] : one \in Sample(4) }
        \cup { [ZeroMdEntry EXCEPT !.mdVolumeType = one] : one \in Sample(1) }

(* A run of Md Entry, written one after another *)
RECURSIVE EncodeMdEntryList(_)
EncodeMdEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntry(Head(messages)) \o EncodeMdEntryList(Tail(messages))

(* As many Md Entry as the field that counts them says *)
RECURSIVE ReadMdEntryList(_, _)
ReadMdEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entry of each kind, for the lists that carry them *)
OneMdEntry == { ZeroMdEntry }

(***************************************************************************)
(* Market Data Refresh Message                                             *)
(***************************************************************************)

MarketDataRefreshMessage ==
    [ classKey              : Sample(4),
      securityId            : Sample(4),
      securityTradingStatus : Sample(1),
      priceType             : Sample(1),
      applSeqNum            : Sample(4),
      prevClosePx           : PrevClosePx,
      tradeVolume           : Sample(4),
      mdEntry               : SampleLists(OneMdEntry) ]

EncodeMarketDataRefreshMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.securityTradingStatus
        \o message.priceType
        \o message.applSeqNum
        \o EncodePrevClosePx(message.prevClosePx)
        \o message.tradeVolume
        \o EncodeUIntBE(Len(message.mdEntry), 1)
        \o EncodeMdEntryList(message.mdEntry)

DecodeMarketDataRefreshMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityTradingStatus.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(priceType.rest, 4) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET prevClosePx == DecodePrevClosePx(applSeqNum.rest) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(prevClosePx.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(tradeVolume.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET mdEntry == ReadMdEntryList(noEntries.rest, noEntries.value) IN IF ~mdEntry.ok THEN Fail ELSE
    Ok([ classKey              |-> classKey.value,
         securityId            |-> securityId.value,
         securityTradingStatus |-> securityTradingStatus.value,
         priceType             |-> priceType.value,
         applSeqNum            |-> applSeqNum.value,
         prevClosePx           |-> prevClosePx.value,
         tradeVolume           |-> tradeVolume.value,
         mdEntry               |-> mdEntry.value ], mdEntry.rest)

ZeroMarketDataRefreshMessage ==
    [ classKey              |-> [i \in 1 .. 4 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      priceType             |-> [i \in 1 .. 1 |-> 0],
      applSeqNum            |-> [i \in 1 .. 4 |-> 0],
      prevClosePx           |-> ZeroPrevClosePx,
      tradeVolume           |-> [i \in 1 .. 4 |-> 0],
      mdEntry               |-> << >> ]

(* Market Data Refresh Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRefreshMessage ==
    { ZeroMarketDataRefreshMessage }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.applSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.prevClosePx = one] : one \in CheckedPrevClosePx }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.mdEntry = one] : one \in SampleLists(OneMdEntry) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx2 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx2(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx2(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx2 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx2 ==
    { ZeroMdEntryPx2 }
        \cup { [ZeroMdEntryPx2 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx2 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entry: 11 bytes                                                      *)
(***************************************************************************)

MdEntry2 ==
    [ mdEntryType  : Sample(1),
      mdEntryPx    : MdEntryPx2,
      mdEntrySize  : Sample(4),
      mdVolumeType : Sample(1) ]

EncodeMdEntry2(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx2(message.mdEntryPx)
        \o message.mdEntrySize
        \o message.mdVolumeType

DecodeMdEntry2(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx2(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 4) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdVolumeType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdVolumeType.ok THEN Fail ELSE
    Ok([ mdEntryType  |-> mdEntryType.value,
         mdEntryPx    |-> mdEntryPx.value,
         mdEntrySize  |-> mdEntrySize.value,
         mdVolumeType |-> mdVolumeType.value ], mdVolumeType.rest)

ZeroMdEntry2 ==
    [ mdEntryType  |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx    |-> ZeroMdEntryPx2,
      mdEntrySize  |-> [i \in 1 .. 4 |-> 0],
      mdVolumeType |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedMdEntry2 ==
    { ZeroMdEntry2 }
        \cup { [ZeroMdEntry2 EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntry2 EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx2 }
        \cup { [ZeroMdEntry2 EXCEPT !.mdEntrySize = one] : one \in Sample(4) }
        \cup { [ZeroMdEntry2 EXCEPT !.mdVolumeType = one] : one \in Sample(1) }

(* A run of Md Entry, written one after another *)
RECURSIVE EncodeMdEntry2List(_)
EncodeMdEntry2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntry2(Head(messages)) \o EncodeMdEntry2List(Tail(messages))

(* As many Md Entry as the field that counts them says *)
RECURSIVE ReadMdEntry2List(_, _)
ReadMdEntry2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntry2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntry2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entry of each kind, for the lists that carry them *)
OneMdEntry2 == { ZeroMdEntry2 }

(***************************************************************************)
(* Current Market Update Message                                           *)
(***************************************************************************)

CurrentMarketUpdateMessage ==
    [ classKey              : Sample(4),
      securityId            : Sample(4),
      securityTradingStatus : Sample(1),
      priceType             : Sample(1),
      mdEntry               : SampleLists(OneMdEntry2) ]

EncodeCurrentMarketUpdateMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.securityTradingStatus
        \o message.priceType
        \o EncodeUIntBE(Len(message.mdEntry), 1)
        \o EncodeMdEntry2List(message.mdEntry)

DecodeCurrentMarketUpdateMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityTradingStatus.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(priceType.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET mdEntry == ReadMdEntry2List(noEntries.rest, noEntries.value) IN IF ~mdEntry.ok THEN Fail ELSE
    Ok([ classKey              |-> classKey.value,
         securityId            |-> securityId.value,
         securityTradingStatus |-> securityTradingStatus.value,
         priceType             |-> priceType.value,
         mdEntry               |-> mdEntry.value ], mdEntry.rest)

ZeroCurrentMarketUpdateMessage ==
    [ classKey              |-> [i \in 1 .. 4 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      priceType             |-> [i \in 1 .. 1 |-> 0],
      mdEntry               |-> << >> ]

(* Current Market Update Message at zero, then each field in turn at the values it is checked at *)
CheckedCurrentMarketUpdateMessage ==
    { ZeroCurrentMarketUpdateMessage }
        \cup { [ZeroCurrentMarketUpdateMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroCurrentMarketUpdateMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroCurrentMarketUpdateMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroCurrentMarketUpdateMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroCurrentMarketUpdateMessage EXCEPT !.mdEntry = one] : one \in SampleLists(OneMdEntry2) }

(***************************************************************************)
(* Eop: 5 bytes                                                            *)
(***************************************************************************)

Eop ==
    [ eopExponent : Sample(1),
      eopMantissa : Sample(4) ]

EncodeEop(message) ==
    message.eopExponent
        \o message.eopMantissa

DecodeEop(bytes) ==
    LET eopExponent == ReadBytes(bytes, 1) IN IF ~eopExponent.ok THEN Fail ELSE
    LET eopMantissa == ReadBytes(eopExponent.rest, 4) IN IF ~eopMantissa.ok THEN Fail ELSE
    Ok([ eopExponent |-> eopExponent.value,
         eopMantissa |-> eopMantissa.value ], eopMantissa.rest)

ZeroEop ==
    [ eopExponent |-> [i \in 1 .. 1 |-> 0],
      eopMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Eop at zero, then each field in turn at the values it is checked at *)
CheckedEop ==
    { ZeroEop }
        \cup { [ZeroEop EXCEPT !.eopExponent = one] : one \in Sample(1) }
        \cup { [ZeroEop EXCEPT !.eopMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Expected Opening Price And Size Message: 19 bytes                       *)
(***************************************************************************)

ExpectedOpeningPriceAndSizeMessage ==
    [ classKey    : Sample(4),
      securityId  : Sample(4),
      eop         : Eop,
      eos         : Sample(4),
      eopType     : Sample(1),
      legalMarket : Sample(1) ]

EncodeExpectedOpeningPriceAndSizeMessage(message) ==
    message.classKey
        \o message.securityId
        \o EncodeEop(message.eop)
        \o message.eos
        \o message.eopType
        \o message.legalMarket

DecodeExpectedOpeningPriceAndSizeMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET eop == DecodeEop(securityId.rest) IN IF ~eop.ok THEN Fail ELSE
    LET eos == ReadBytes(eop.rest, 4) IN IF ~eos.ok THEN Fail ELSE
    LET eopType == ReadBytes(eos.rest, 1) IN IF ~eopType.ok THEN Fail ELSE
    LET legalMarket == ReadBytes(eopType.rest, 1) IN IF ~legalMarket.ok THEN Fail ELSE
    Ok([ classKey    |-> classKey.value,
         securityId  |-> securityId.value,
         eop         |-> eop.value,
         eos         |-> eos.value,
         eopType     |-> eopType.value,
         legalMarket |-> legalMarket.value ], legalMarket.rest)

ZeroExpectedOpeningPriceAndSizeMessage ==
    [ classKey    |-> [i \in 1 .. 4 |-> 0],
      securityId  |-> [i \in 1 .. 4 |-> 0],
      eop         |-> ZeroEop,
      eos         |-> [i \in 1 .. 4 |-> 0],
      eopType     |-> [i \in 1 .. 1 |-> 0],
      legalMarket |-> [i \in 1 .. 1 |-> 0] ]

(* Expected Opening Price And Size Message at zero, then each field in turn at the values it is checked at *)
CheckedExpectedOpeningPriceAndSizeMessage ==
    { ZeroExpectedOpeningPriceAndSizeMessage }
        \cup { [ZeroExpectedOpeningPriceAndSizeMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroExpectedOpeningPriceAndSizeMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExpectedOpeningPriceAndSizeMessage EXCEPT !.eop = one] : one \in CheckedEop }
        \cup { [ZeroExpectedOpeningPriceAndSizeMessage EXCEPT !.eos = one] : one \in Sample(4) }
        \cup { [ZeroExpectedOpeningPriceAndSizeMessage EXCEPT !.eopType = one] : one \in Sample(1) }
        \cup { [ZeroExpectedOpeningPriceAndSizeMessage EXCEPT !.legalMarket = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

SecurityDefinitionMessageCode == 13  \* 0x0d
MarketDataRefreshMessageCode == 20  \* 0x14
CurrentMarketUpdateMessageCode == 12  \* 0x0c
ExpectedOpeningPriceAndSizeMessageCode == 15  \* 0x0f
HeartbeatMessageCode == 16  \* 0x10

Payload ==
    [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {MarketDataRefreshMessageCode}, body : MarketDataRefreshMessage ]
        \cup [ tag : {CurrentMarketUpdateMessageCode}, body : CurrentMarketUpdateMessage ]
        \cup [ tag : {ExpectedOpeningPriceAndSizeMessageCode}, body : ExpectedOpeningPriceAndSizeMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = MarketDataRefreshMessageCode -> EncodeMarketDataRefreshMessage(message.body)
      [] message.tag = CurrentMarketUpdateMessageCode -> EncodeCurrentMarketUpdateMessage(message.body)
      [] message.tag = ExpectedOpeningPriceAndSizeMessageCode -> EncodeExpectedOpeningPriceAndSizeMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = MarketDataRefreshMessageCode -> DecodeMarketDataRefreshMessage(bytes)
              [] tag = CurrentMarketUpdateMessageCode -> DecodeCurrentMarketUpdateMessage(bytes)
              [] tag = ExpectedOpeningPriceAndSizeMessageCode -> DecodeExpectedOpeningPriceAndSizeMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> MarketDataRefreshMessageCode, body |-> one] : one \in CheckedMarketDataRefreshMessage }
        \cup { [tag |-> CurrentMarketUpdateMessageCode, body |-> one] : one \in CheckedCurrentMarketUpdateMessage }
        \cup { [tag |-> ExpectedOpeningPriceAndSizeMessageCode, body |-> one] : one \in CheckedExpectedOpeningPriceAndSizeMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength : Sample(2),
      messageType   : Sample(1),
      msgSeqNum     : Sample(4),
      payload       : Payload ]

EncodeMessage(message) ==
    message.messageLength
        \o EncodeUIntBE(message.payload.tag, 1)
        \o message.messageType
        \o message.msgSeqNum
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET messageLength == ReadBytes(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(messageLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET messageType == ReadBytes(templateId.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET msgSeqNum == ReadBytes(messageType.rest, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, msgSeqNum.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ messageLength |-> messageLength.value,
         messageType   |-> messageType.value,
         msgSeqNum     |-> msgSeqNum.value,
         payload       |-> payload.value ], payload.rest)

ZeroMessage ==
    [ messageLength |-> [i \in 1 .. 2 |-> 0],
      messageType   |-> [i \in 1 .. 1 |-> 0],
      msgSeqNum     |-> [i \in 1 .. 4 |-> 0],
      payload       |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.messageType = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDataRefreshMessageCode, body |-> ZeroMarketDataRefreshMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CurrentMarketUpdateMessageCode, body |-> ZeroCurrentMarketUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpectedOpeningPriceAndSizeMessageCode, body |-> ZeroExpectedOpeningPriceAndSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version        : Sample(1),
      packetLength   : Sample(2),
      sendingTime    : Sample(8),
      firstMsgSeqNum : Sample(4),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.version
        \o message.packetLength
        \o message.sendingTime
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.firstMsgSeqNum
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET packetLength == ReadBytes(version.rest, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(packetLength.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sendingTime.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET firstMsgSeqNum == ReadBytes(messageCount.rest, 4) IN IF ~firstMsgSeqNum.ok THEN Fail ELSE
    LET message == ReadMessageList(firstMsgSeqNum.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ version        |-> version.value,
         packetLength   |-> packetLength.value,
         sendingTime    |-> sendingTime.value,
         firstMsgSeqNum |-> firstMsgSeqNum.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ version        |-> [i \in 1 .. 1 |-> 0],
      packetLength   |-> [i \in 1 .. 2 |-> 0],
      sendingTime    |-> [i \in 1 .. 8 |-> 0],
      firstMsgSeqNum |-> [i \in 1 .. 4 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.firstMsgSeqNum = one] : one \in Sample(4) }
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

(* Every Security Type decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityType ==
    \A message \in CheckedSecurityType :
        LET read == DecodeSecurityType(EncodeSecurityType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol ==
    \A message \in CheckedSymbol :
        LET read == DecodeSymbol(EncodeSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Location Id decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetLocationId ==
    \A message \in CheckedTargetLocationId :
        LET read == DecodeTargetLocationId(EncodeTargetLocationId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strike Price decodes back to what was encoded, and leaves nothing over *)
RoundTripStrikePrice ==
    \A message \in CheckedStrikePrice :
        LET read == DecodeStrikePrice(EncodeStrikePrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Strike Price Fraction decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumStrikePriceFraction ==
    \A message \in CheckedMinimumStrikePriceFraction :
        LET read == DecodeMinimumStrikePriceFraction(EncodeMinimumStrikePriceFraction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Strike Price decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxStrikePrice ==
    \A message \in CheckedMaxStrikePrice :
        LET read == DecodeMaxStrikePrice(EncodeMaxStrikePrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Premium Break Point decodes back to what was encoded, and leaves nothing over *)
RoundTripPremiumBreakPoint ==
    \A message \in CheckedPremiumBreakPoint :
        LET read == DecodePremiumBreakPoint(EncodePremiumBreakPoint(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Above Premium Fraction decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumAbovePremiumFraction ==
    \A message \in CheckedMinimumAbovePremiumFraction :
        LET read == DecodeMinimumAbovePremiumFraction(EncodeMinimumAbovePremiumFraction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Below Premium Fraction decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumBelowPremiumFraction ==
    \A message \in CheckedMinimumBelowPremiumFraction :
        LET read == DecodeMinimumBelowPremiumFraction(EncodeMinimumBelowPremiumFraction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Currency Code decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrencyCode ==
    \A message \in CheckedCurrencyCode :
        LET read == DecodeCurrencyCode(EncodeCurrencyCode(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingSymbol ==
    \A message \in CheckedUnderlyingSymbol :
        LET read == DecodeUnderlyingSymbol(EncodeUnderlyingSymbol(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Type decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingType ==
    \A message \in CheckedUnderlyingType :
        LET read == DecodeUnderlyingType(EncodeUnderlyingType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionLeg ==
    \A message \in CheckedSecurityDefinitionLeg :
        LET read == DecodeSecurityDefinitionLeg(EncodeSecurityDefinitionLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Prev Close Px decodes back to what was encoded, and leaves nothing over *)
RoundTripPrevClosePx ==
    \A message \in CheckedPrevClosePx :
        LET read == DecodePrevClosePx(EncodePrevClosePx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx ==
    \A message \in CheckedMdEntryPx :
        LET read == DecodeMdEntryPx(EncodeMdEntryPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntry ==
    \A message \in CheckedMdEntry :
        LET read == DecodeMdEntry(EncodeMdEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRefreshMessage ==
    \A message \in CheckedMarketDataRefreshMessage :
        LET read == DecodeMarketDataRefreshMessage(EncodeMarketDataRefreshMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx2 ==
    \A message \in CheckedMdEntryPx2 :
        LET read == DecodeMdEntryPx2(EncodeMdEntryPx2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntry2 ==
    \A message \in CheckedMdEntry2 :
        LET read == DecodeMdEntry2(EncodeMdEntry2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Current Market Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrentMarketUpdateMessage ==
    \A message \in CheckedCurrentMarketUpdateMessage :
        LET read == DecodeCurrentMarketUpdateMessage(EncodeCurrentMarketUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Eop decodes back to what was encoded, and leaves nothing over *)
RoundTripEop ==
    \A message \in CheckedEop :
        LET read == DecodeEop(EncodeEop(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expected Opening Price And Size Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExpectedOpeningPriceAndSizeMessage ==
    \A message \in CheckedExpectedOpeningPriceAndSizeMessage :
        LET read == DecodeExpectedOpeningPriceAndSizeMessage(EncodeExpectedOpeningPriceAndSizeMessage(message))
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
