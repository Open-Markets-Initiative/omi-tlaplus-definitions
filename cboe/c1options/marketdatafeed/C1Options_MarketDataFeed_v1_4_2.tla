------------------ MODULE C1Options_MarketDataFeed_v1_4_2 ------------------
(***************************************************************************)
(* Chicago Board Options Exchange Market Data Feed v1.4.2                  *)
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
(* Current Market Refresh Message                                          *)
(***************************************************************************)

CurrentMarketRefreshMessage ==
    [ classKey              : Sample(4),
      securityId            : Sample(4),
      securityTradingStatus : Sample(1),
      priceType             : Sample(1),
      applSeqNum            : Sample(4),
      mdEntry               : SampleLists(OneMdEntry) ]

EncodeCurrentMarketRefreshMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.securityTradingStatus
        \o message.priceType
        \o message.applSeqNum
        \o EncodeUIntBE(Len(message.mdEntry), 1)
        \o EncodeMdEntryList(message.mdEntry)

DecodeCurrentMarketRefreshMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityTradingStatus.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(priceType.rest, 4) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(applSeqNum.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET mdEntry == ReadMdEntryList(noEntries.rest, noEntries.value) IN IF ~mdEntry.ok THEN Fail ELSE
    Ok([ classKey              |-> classKey.value,
         securityId            |-> securityId.value,
         securityTradingStatus |-> securityTradingStatus.value,
         priceType             |-> priceType.value,
         applSeqNum            |-> applSeqNum.value,
         mdEntry               |-> mdEntry.value ], mdEntry.rest)

ZeroCurrentMarketRefreshMessage ==
    [ classKey              |-> [i \in 1 .. 4 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      priceType             |-> [i \in 1 .. 1 |-> 0],
      applSeqNum            |-> [i \in 1 .. 4 |-> 0],
      mdEntry               |-> << >> ]

(* Current Market Refresh Message at zero, then each field in turn at the values it is checked at *)
CheckedCurrentMarketRefreshMessage ==
    { ZeroCurrentMarketRefreshMessage }
        \cup { [ZeroCurrentMarketRefreshMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroCurrentMarketRefreshMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroCurrentMarketRefreshMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroCurrentMarketRefreshMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroCurrentMarketRefreshMessage EXCEPT !.applSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCurrentMarketRefreshMessage EXCEPT !.mdEntry = one] : one \in SampleLists(OneMdEntry) }

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
      mdEntry               : SampleLists(OneMdEntry2) ]

EncodeMarketDataRefreshMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.securityTradingStatus
        \o message.priceType
        \o message.applSeqNum
        \o EncodePrevClosePx(message.prevClosePx)
        \o message.tradeVolume
        \o EncodeUIntBE(Len(message.mdEntry), 1)
        \o EncodeMdEntry2List(message.mdEntry)

DecodeMarketDataRefreshMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityTradingStatus.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET applSeqNum == ReadBytes(priceType.rest, 4) IN IF ~applSeqNum.ok THEN Fail ELSE
    LET prevClosePx == DecodePrevClosePx(applSeqNum.rest) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(prevClosePx.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(tradeVolume.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET mdEntry == ReadMdEntry2List(noEntries.rest, noEntries.value) IN IF ~mdEntry.ok THEN Fail ELSE
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
        \cup { [ZeroMarketDataRefreshMessage EXCEPT !.mdEntry = one] : one \in SampleLists(OneMdEntry2) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx3 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx3(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx3(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx3 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx3 ==
    { ZeroMdEntryPx3 }
        \cup { [ZeroMdEntryPx3 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx3 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entry: 11 bytes                                                      *)
(***************************************************************************)

MdEntry3 ==
    [ mdEntryType  : Sample(1),
      mdEntryPx    : MdEntryPx3,
      mdEntrySize  : Sample(4),
      mdVolumeType : Sample(1) ]

EncodeMdEntry3(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx3(message.mdEntryPx)
        \o message.mdEntrySize
        \o message.mdVolumeType

DecodeMdEntry3(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx3(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 4) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET mdVolumeType == ReadBytes(mdEntrySize.rest, 1) IN IF ~mdVolumeType.ok THEN Fail ELSE
    Ok([ mdEntryType  |-> mdEntryType.value,
         mdEntryPx    |-> mdEntryPx.value,
         mdEntrySize  |-> mdEntrySize.value,
         mdVolumeType |-> mdVolumeType.value ], mdVolumeType.rest)

ZeroMdEntry3 ==
    [ mdEntryType  |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx    |-> ZeroMdEntryPx3,
      mdEntrySize  |-> [i \in 1 .. 4 |-> 0],
      mdVolumeType |-> [i \in 1 .. 1 |-> 0] ]

(* Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedMdEntry3 ==
    { ZeroMdEntry3 }
        \cup { [ZeroMdEntry3 EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroMdEntry3 EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx3 }
        \cup { [ZeroMdEntry3 EXCEPT !.mdEntrySize = one] : one \in Sample(4) }
        \cup { [ZeroMdEntry3 EXCEPT !.mdVolumeType = one] : one \in Sample(1) }

(* A run of Md Entry, written one after another *)
RECURSIVE EncodeMdEntry3List(_)
EncodeMdEntry3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMdEntry3(Head(messages)) \o EncodeMdEntry3List(Tail(messages))

(* As many Md Entry as the field that counts them says *)
RECURSIVE ReadMdEntry3List(_, _)
ReadMdEntry3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMdEntry3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMdEntry3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Md Entry of each kind, for the lists that carry them *)
OneMdEntry3 == { ZeroMdEntry3 }

(***************************************************************************)
(* Current Market Update Message                                           *)
(***************************************************************************)

CurrentMarketUpdateMessage ==
    [ classKey              : Sample(4),
      securityId            : Sample(4),
      securityTradingStatus : Sample(1),
      priceType             : Sample(1),
      mdEntry               : SampleLists(OneMdEntry3) ]

EncodeCurrentMarketUpdateMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.securityTradingStatus
        \o message.priceType
        \o EncodeUIntBE(Len(message.mdEntry), 1)
        \o EncodeMdEntry3List(message.mdEntry)

DecodeCurrentMarketUpdateMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityTradingStatus.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(priceType.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET mdEntry == ReadMdEntry3List(noEntries.rest, noEntries.value) IN IF ~mdEntry.ok THEN Fail ELSE
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
        \cup { [ZeroCurrentMarketUpdateMessage EXCEPT !.mdEntry = one] : one \in SampleLists(OneMdEntry3) }

(***************************************************************************)
(* Prev Close Px: 5 bytes                                                  *)
(***************************************************************************)

PrevClosePx2 ==
    [ prevClosePxExponent : Sample(1),
      prevClosePxMantissa : Sample(4) ]

EncodePrevClosePx2(message) ==
    message.prevClosePxExponent
        \o message.prevClosePxMantissa

DecodePrevClosePx2(bytes) ==
    LET prevClosePxExponent == ReadBytes(bytes, 1) IN IF ~prevClosePxExponent.ok THEN Fail ELSE
    LET prevClosePxMantissa == ReadBytes(prevClosePxExponent.rest, 4) IN IF ~prevClosePxMantissa.ok THEN Fail ELSE
    Ok([ prevClosePxExponent |-> prevClosePxExponent.value,
         prevClosePxMantissa |-> prevClosePxMantissa.value ], prevClosePxMantissa.rest)

ZeroPrevClosePx2 ==
    [ prevClosePxExponent |-> [i \in 1 .. 1 |-> 0],
      prevClosePxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Prev Close Px at zero, then each field in turn at the values it is checked at *)
CheckedPrevClosePx2 ==
    { ZeroPrevClosePx2 }
        \cup { [ZeroPrevClosePx2 EXCEPT !.prevClosePxExponent = one] : one \in Sample(1) }
        \cup { [ZeroPrevClosePx2 EXCEPT !.prevClosePxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx4 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx4(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx4(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx4 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx4 ==
    { ZeroMdEntryPx4 }
        \cup { [ZeroMdEntryPx4 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx4 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Recap Update Md Entry: 10 bytes                                         *)
(***************************************************************************)

RecapUpdateMdEntry ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx4,
      mdEntrySize : Sample(4) ]

EncodeRecapUpdateMdEntry(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx4(message.mdEntryPx)
        \o message.mdEntrySize

DecodeRecapUpdateMdEntry(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx4(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 4) IN IF ~mdEntrySize.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value,
         mdEntrySize |-> mdEntrySize.value ], mdEntrySize.rest)

ZeroRecapUpdateMdEntry ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx4,
      mdEntrySize |-> [i \in 1 .. 4 |-> 0] ]

(* Recap Update Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedRecapUpdateMdEntry ==
    { ZeroRecapUpdateMdEntry }
        \cup { [ZeroRecapUpdateMdEntry EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroRecapUpdateMdEntry EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx4 }
        \cup { [ZeroRecapUpdateMdEntry EXCEPT !.mdEntrySize = one] : one \in Sample(4) }

(* A run of Recap Update Md Entry, written one after another *)
RECURSIVE EncodeRecapUpdateMdEntryList(_)
EncodeRecapUpdateMdEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRecapUpdateMdEntry(Head(messages)) \o EncodeRecapUpdateMdEntryList(Tail(messages))

(* As many Recap Update Md Entry as the field that counts them says *)
RECURSIVE ReadRecapUpdateMdEntryList(_, _)
ReadRecapUpdateMdEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRecapUpdateMdEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRecapUpdateMdEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Recap Update Md Entry of each kind, for the lists that carry them *)
OneRecapUpdateMdEntry == { ZeroRecapUpdateMdEntry }

(***************************************************************************)
(* Recap Update Message                                                    *)
(***************************************************************************)

RecapUpdateMessage ==
    [ classKey           : Sample(4),
      securityId         : Sample(4),
      priceType          : Sample(1),
      prevClosePx        : PrevClosePx2,
      tradeVolume        : Sample(4),
      recapUpdateMdEntry : SampleLists(OneRecapUpdateMdEntry) ]

EncodeRecapUpdateMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.priceType
        \o EncodePrevClosePx2(message.prevClosePx)
        \o message.tradeVolume
        \o EncodeUIntBE(Len(message.recapUpdateMdEntry), 1)
        \o EncodeRecapUpdateMdEntryList(message.recapUpdateMdEntry)

DecodeRecapUpdateMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityId.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET prevClosePx == DecodePrevClosePx2(priceType.rest) IN IF ~prevClosePx.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(prevClosePx.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(tradeVolume.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET recapUpdateMdEntry == ReadRecapUpdateMdEntryList(noEntries.rest, noEntries.value) IN IF ~recapUpdateMdEntry.ok THEN Fail ELSE
    Ok([ classKey           |-> classKey.value,
         securityId         |-> securityId.value,
         priceType          |-> priceType.value,
         prevClosePx        |-> prevClosePx.value,
         tradeVolume        |-> tradeVolume.value,
         recapUpdateMdEntry |-> recapUpdateMdEntry.value ], recapUpdateMdEntry.rest)

ZeroRecapUpdateMessage ==
    [ classKey           |-> [i \in 1 .. 4 |-> 0],
      securityId         |-> [i \in 1 .. 4 |-> 0],
      priceType          |-> [i \in 1 .. 1 |-> 0],
      prevClosePx        |-> ZeroPrevClosePx2,
      tradeVolume        |-> [i \in 1 .. 4 |-> 0],
      recapUpdateMdEntry |-> << >> ]

(* Recap Update Message at zero, then each field in turn at the values it is checked at *)
CheckedRecapUpdateMessage ==
    { ZeroRecapUpdateMessage }
        \cup { [ZeroRecapUpdateMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroRecapUpdateMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroRecapUpdateMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroRecapUpdateMessage EXCEPT !.prevClosePx = one] : one \in CheckedPrevClosePx2 }
        \cup { [ZeroRecapUpdateMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroRecapUpdateMessage EXCEPT !.recapUpdateMdEntry = one] : one \in SampleLists(OneRecapUpdateMdEntry) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx5 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx5(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx5(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx5 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx5 ==
    { ZeroMdEntryPx5 }
        \cup { [ZeroMdEntryPx5 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx5 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Condition                                                         *)
(***************************************************************************)

TradeCondition ==
    [ tradeConditionText : SampleBytes ]

EncodeTradeCondition(message) ==
    EncodeUIntBE(Len(message.tradeConditionText), 1)
        \o message.tradeConditionText

DecodeTradeCondition(bytes) ==
    LET tradeConditionLength == ReadUIntBE(bytes, 1) IN IF ~tradeConditionLength.ok THEN Fail ELSE
    LET tradeConditionText == ReadBytes(tradeConditionLength.rest, tradeConditionLength.value) IN IF ~tradeConditionText.ok THEN Fail ELSE
    Ok([ tradeConditionText |-> tradeConditionText.value ], tradeConditionText.rest)

ZeroTradeCondition ==
    [ tradeConditionText |-> << >> ]

(* Trade Condition at zero, then each field in turn at the values it is checked at *)
CheckedTradeCondition ==
    { ZeroTradeCondition }
        \cup { [ZeroTradeCondition EXCEPT !.tradeConditionText = one] : one \in SampleBytes }

(***************************************************************************)
(* Ticker Md Entry                                                         *)
(***************************************************************************)

TickerMdEntry ==
    [ mdEntryType    : Sample(1),
      mdEntryPx      : MdEntryPx5,
      mdEntrySize    : Sample(4),
      tradeCondition : TradeCondition ]

EncodeTickerMdEntry(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx5(message.mdEntryPx)
        \o message.mdEntrySize
        \o EncodeTradeCondition(message.tradeCondition)

DecodeTickerMdEntry(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx5(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    LET mdEntrySize == ReadBytes(mdEntryPx.rest, 4) IN IF ~mdEntrySize.ok THEN Fail ELSE
    LET tradeCondition == DecodeTradeCondition(mdEntrySize.rest) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ mdEntryType    |-> mdEntryType.value,
         mdEntryPx      |-> mdEntryPx.value,
         mdEntrySize    |-> mdEntrySize.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTickerMdEntry ==
    [ mdEntryType    |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx      |-> ZeroMdEntryPx5,
      mdEntrySize    |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> ZeroTradeCondition ]

(* Ticker Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedTickerMdEntry ==
    { ZeroTickerMdEntry }
        \cup { [ZeroTickerMdEntry EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroTickerMdEntry EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx5 }
        \cup { [ZeroTickerMdEntry EXCEPT !.mdEntrySize = one] : one \in Sample(4) }
        \cup { [ZeroTickerMdEntry EXCEPT !.tradeCondition = one] : one \in CheckedTradeCondition }

(* A run of Ticker Md Entry, written one after another *)
RECURSIVE EncodeTickerMdEntryList(_)
EncodeTickerMdEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTickerMdEntry(Head(messages)) \o EncodeTickerMdEntryList(Tail(messages))

(* As many Ticker Md Entry as the field that counts them says *)
RECURSIVE ReadTickerMdEntryList(_, _)
ReadTickerMdEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTickerMdEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTickerMdEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Ticker Md Entry of each kind, for the lists that carry them *)
OneTickerMdEntry == { ZeroTickerMdEntry }

(***************************************************************************)
(* Ticker Message                                                          *)
(***************************************************************************)

TickerMessage ==
    [ classKey      : Sample(4),
      securityId    : Sample(4),
      priceType     : Sample(1),
      tickerMdEntry : SampleLists(OneTickerMdEntry) ]

EncodeTickerMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.priceType
        \o EncodeUIntBE(Len(message.tickerMdEntry), 1)
        \o EncodeTickerMdEntryList(message.tickerMdEntry)

DecodeTickerMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityId.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(priceType.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET tickerMdEntry == ReadTickerMdEntryList(noEntries.rest, noEntries.value) IN IF ~tickerMdEntry.ok THEN Fail ELSE
    Ok([ classKey      |-> classKey.value,
         securityId    |-> securityId.value,
         priceType     |-> priceType.value,
         tickerMdEntry |-> tickerMdEntry.value ], tickerMdEntry.rest)

ZeroTickerMessage ==
    [ classKey      |-> [i \in 1 .. 4 |-> 0],
      securityId    |-> [i \in 1 .. 4 |-> 0],
      priceType     |-> [i \in 1 .. 1 |-> 0],
      tickerMdEntry |-> << >> ]

(* Ticker Message at zero, then each field in turn at the values it is checked at *)
CheckedTickerMessage ==
    { ZeroTickerMessage }
        \cup { [ZeroTickerMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroTickerMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroTickerMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroTickerMessage EXCEPT !.tickerMdEntry = one] : one \in SampleLists(OneTickerMdEntry) }

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
(* Symbol                                                                  *)
(***************************************************************************)

Symbol2 ==
    [ symbolText : SampleBytes ]

EncodeSymbol2(message) ==
    EncodeUIntBE(Len(message.symbolText), 1)
        \o message.symbolText

DecodeSymbol2(bytes) ==
    LET symbolLength == ReadUIntBE(bytes, 1) IN IF ~symbolLength.ok THEN Fail ELSE
    LET symbolText == ReadBytes(symbolLength.rest, symbolLength.value) IN IF ~symbolText.ok THEN Fail ELSE
    Ok([ symbolText |-> symbolText.value ], symbolText.rest)

ZeroSymbol2 ==
    [ symbolText |-> << >> ]

(* Symbol at zero, then each field in turn at the values it is checked at *)
CheckedSymbol2 ==
    { ZeroSymbol2 }
        \cup { [ZeroSymbol2 EXCEPT !.symbolText = one] : one \in SampleBytes }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx6 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx6(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx6(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx6 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx6 ==
    { ZeroMdEntryPx6 }
        \cup { [ZeroMdEntryPx6 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx6 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Index Value Md Entry: 6 bytes                                           *)
(***************************************************************************)

IndexValueMdEntry ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx6 ]

EncodeIndexValueMdEntry(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx6(message.mdEntryPx)

DecodeIndexValueMdEntry(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx6(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroIndexValueMdEntry ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx6 ]

(* Index Value Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueMdEntry ==
    { ZeroIndexValueMdEntry }
        \cup { [ZeroIndexValueMdEntry EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroIndexValueMdEntry EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx6 }

(* A run of Index Value Md Entry, written one after another *)
RECURSIVE EncodeIndexValueMdEntryList(_)
EncodeIndexValueMdEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeIndexValueMdEntry(Head(messages)) \o EncodeIndexValueMdEntryList(Tail(messages))

(* As many Index Value Md Entry as the field that counts them says *)
RECURSIVE ReadIndexValueMdEntryList(_, _)
ReadIndexValueMdEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeIndexValueMdEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadIndexValueMdEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Index Value Md Entry of each kind, for the lists that carry them *)
OneIndexValueMdEntry == { ZeroIndexValueMdEntry }

(***************************************************************************)
(* Index Value Message                                                     *)
(***************************************************************************)

IndexValueMessage ==
    [ symbol            : Symbol2,
      indexValueMdEntry : SampleLists(OneIndexValueMdEntry) ]

EncodeIndexValueMessage(message) ==
    EncodeSymbol2(message.symbol)
        \o EncodeUIntBE(Len(message.indexValueMdEntry), 1)
        \o EncodeIndexValueMdEntryList(message.indexValueMdEntry)

DecodeIndexValueMessage(bytes) ==
    LET symbol == DecodeSymbol2(bytes) IN IF ~symbol.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(symbol.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET indexValueMdEntry == ReadIndexValueMdEntryList(noEntries.rest, noEntries.value) IN IF ~indexValueMdEntry.ok THEN Fail ELSE
    Ok([ symbol            |-> symbol.value,
         indexValueMdEntry |-> indexValueMdEntry.value ], indexValueMdEntry.rest)

ZeroIndexValueMessage ==
    [ symbol            |-> ZeroSymbol2,
      indexValueMdEntry |-> << >> ]

(* Index Value Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexValueMessage ==
    { ZeroIndexValueMessage }
        \cup { [ZeroIndexValueMessage EXCEPT !.symbol = one] : one \in CheckedSymbol2 }
        \cup { [ZeroIndexValueMessage EXCEPT !.indexValueMdEntry = one] : one \in SampleLists(OneIndexValueMdEntry) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx7 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx7(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx7(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx7 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx7 ==
    { ZeroMdEntryPx7 }
        \cup { [ZeroMdEntryPx7 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx7 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Settlement Value Md Entry: 6 bytes                                      *)
(***************************************************************************)

SettlementValueMdEntry ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx7 ]

EncodeSettlementValueMdEntry(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx7(message.mdEntryPx)

DecodeSettlementValueMdEntry(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx7(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroSettlementValueMdEntry ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx7 ]

(* Settlement Value Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedSettlementValueMdEntry ==
    { ZeroSettlementValueMdEntry }
        \cup { [ZeroSettlementValueMdEntry EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementValueMdEntry EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx7 }

(* A run of Settlement Value Md Entry, written one after another *)
RECURSIVE EncodeSettlementValueMdEntryList(_)
EncodeSettlementValueMdEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSettlementValueMdEntry(Head(messages)) \o EncodeSettlementValueMdEntryList(Tail(messages))

(* As many Settlement Value Md Entry as the field that counts them says *)
RECURSIVE ReadSettlementValueMdEntryList(_, _)
ReadSettlementValueMdEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSettlementValueMdEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSettlementValueMdEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Settlement Value Md Entry of each kind, for the lists that carry them *)
OneSettlementValueMdEntry == { ZeroSettlementValueMdEntry }

(***************************************************************************)
(* Settlement Value Message                                                *)
(***************************************************************************)

SettlementValueMessage ==
    [ classKey               : Sample(4),
      securityId             : Sample(4),
      priceType              : Sample(1),
      settlementValueMdEntry : SampleLists(OneSettlementValueMdEntry) ]

EncodeSettlementValueMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.priceType
        \o EncodeUIntBE(Len(message.settlementValueMdEntry), 1)
        \o EncodeSettlementValueMdEntryList(message.settlementValueMdEntry)

DecodeSettlementValueMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityId.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(priceType.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET settlementValueMdEntry == ReadSettlementValueMdEntryList(noEntries.rest, noEntries.value) IN IF ~settlementValueMdEntry.ok THEN Fail ELSE
    Ok([ classKey               |-> classKey.value,
         securityId             |-> securityId.value,
         priceType              |-> priceType.value,
         settlementValueMdEntry |-> settlementValueMdEntry.value ], settlementValueMdEntry.rest)

ZeroSettlementValueMessage ==
    [ classKey               |-> [i \in 1 .. 4 |-> 0],
      securityId             |-> [i \in 1 .. 4 |-> 0],
      priceType              |-> [i \in 1 .. 1 |-> 0],
      settlementValueMdEntry |-> << >> ]

(* Settlement Value Message at zero, then each field in turn at the values it is checked at *)
CheckedSettlementValueMessage ==
    { ZeroSettlementValueMessage }
        \cup { [ZeroSettlementValueMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSettlementValueMessage EXCEPT !.settlementValueMdEntry = one] : one \in SampleLists(OneSettlementValueMdEntry) }

(***************************************************************************)
(* Net Chg Prev Day: 5 bytes                                               *)
(***************************************************************************)

NetChgPrevDay ==
    [ netChgPrevDayExponent : Sample(1),
      netChgPrevDayMantissa : Sample(4) ]

EncodeNetChgPrevDay(message) ==
    message.netChgPrevDayExponent
        \o message.netChgPrevDayMantissa

DecodeNetChgPrevDay(bytes) ==
    LET netChgPrevDayExponent == ReadBytes(bytes, 1) IN IF ~netChgPrevDayExponent.ok THEN Fail ELSE
    LET netChgPrevDayMantissa == ReadBytes(netChgPrevDayExponent.rest, 4) IN IF ~netChgPrevDayMantissa.ok THEN Fail ELSE
    Ok([ netChgPrevDayExponent |-> netChgPrevDayExponent.value,
         netChgPrevDayMantissa |-> netChgPrevDayMantissa.value ], netChgPrevDayMantissa.rest)

ZeroNetChgPrevDay ==
    [ netChgPrevDayExponent |-> [i \in 1 .. 1 |-> 0],
      netChgPrevDayMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Net Chg Prev Day at zero, then each field in turn at the values it is checked at *)
CheckedNetChgPrevDay ==
    { ZeroNetChgPrevDay }
        \cup { [ZeroNetChgPrevDay EXCEPT !.netChgPrevDayExponent = one] : one \in Sample(1) }
        \cup { [ZeroNetChgPrevDay EXCEPT !.netChgPrevDayMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Underlying Px: 5 bytes                                                  *)
(***************************************************************************)

UnderlyingPx ==
    [ underlyingPxExponent : Sample(1),
      underlyingPxMantissa : Sample(4) ]

EncodeUnderlyingPx(message) ==
    message.underlyingPxExponent
        \o message.underlyingPxMantissa

DecodeUnderlyingPx(bytes) ==
    LET underlyingPxExponent == ReadBytes(bytes, 1) IN IF ~underlyingPxExponent.ok THEN Fail ELSE
    LET underlyingPxMantissa == ReadBytes(underlyingPxExponent.rest, 4) IN IF ~underlyingPxMantissa.ok THEN Fail ELSE
    Ok([ underlyingPxExponent |-> underlyingPxExponent.value,
         underlyingPxMantissa |-> underlyingPxMantissa.value ], underlyingPxMantissa.rest)

ZeroUnderlyingPx ==
    [ underlyingPxExponent |-> [i \in 1 .. 1 |-> 0],
      underlyingPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Px at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingPx ==
    { ZeroUnderlyingPx }
        \cup { [ZeroUnderlyingPx EXCEPT !.underlyingPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingPx EXCEPT !.underlyingPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Md Entry Px: 5 bytes                                                    *)
(***************************************************************************)

MdEntryPx8 ==
    [ mdEntryPxExponent : Sample(1),
      mdEntryPxMantissa : Sample(4) ]

EncodeMdEntryPx8(message) ==
    message.mdEntryPxExponent
        \o message.mdEntryPxMantissa

DecodeMdEntryPx8(bytes) ==
    LET mdEntryPxExponent == ReadBytes(bytes, 1) IN IF ~mdEntryPxExponent.ok THEN Fail ELSE
    LET mdEntryPxMantissa == ReadBytes(mdEntryPxExponent.rest, 4) IN IF ~mdEntryPxMantissa.ok THEN Fail ELSE
    Ok([ mdEntryPxExponent |-> mdEntryPxExponent.value,
         mdEntryPxMantissa |-> mdEntryPxMantissa.value ], mdEntryPxMantissa.rest)

ZeroMdEntryPx8 ==
    [ mdEntryPxExponent |-> [i \in 1 .. 1 |-> 0],
      mdEntryPxMantissa |-> [i \in 1 .. 4 |-> 0] ]

(* Md Entry Px at zero, then each field in turn at the values it is checked at *)
CheckedMdEntryPx8 ==
    { ZeroMdEntryPx8 }
        \cup { [ZeroMdEntryPx8 EXCEPT !.mdEntryPxExponent = one] : one \in Sample(1) }
        \cup { [ZeroMdEntryPx8 EXCEPT !.mdEntryPxMantissa = one] : one \in Sample(4) }

(***************************************************************************)
(* Summary Md Entry: 6 bytes                                               *)
(***************************************************************************)

SummaryMdEntry ==
    [ mdEntryType : Sample(1),
      mdEntryPx   : MdEntryPx8 ]

EncodeSummaryMdEntry(message) ==
    message.mdEntryType
        \o EncodeMdEntryPx8(message.mdEntryPx)

DecodeSummaryMdEntry(bytes) ==
    LET mdEntryType == ReadBytes(bytes, 1) IN IF ~mdEntryType.ok THEN Fail ELSE
    LET mdEntryPx == DecodeMdEntryPx8(mdEntryType.rest) IN IF ~mdEntryPx.ok THEN Fail ELSE
    Ok([ mdEntryType |-> mdEntryType.value,
         mdEntryPx   |-> mdEntryPx.value ], mdEntryPx.rest)

ZeroSummaryMdEntry ==
    [ mdEntryType |-> [i \in 1 .. 1 |-> 0],
      mdEntryPx   |-> ZeroMdEntryPx8 ]

(* Summary Md Entry at zero, then each field in turn at the values it is checked at *)
CheckedSummaryMdEntry ==
    { ZeroSummaryMdEntry }
        \cup { [ZeroSummaryMdEntry EXCEPT !.mdEntryType = one] : one \in Sample(1) }
        \cup { [ZeroSummaryMdEntry EXCEPT !.mdEntryPx = one] : one \in CheckedMdEntryPx8 }

(* A run of Summary Md Entry, written one after another *)
RECURSIVE EncodeSummaryMdEntryList(_)
EncodeSummaryMdEntryList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSummaryMdEntry(Head(messages)) \o EncodeSummaryMdEntryList(Tail(messages))

(* As many Summary Md Entry as the field that counts them says *)
RECURSIVE ReadSummaryMdEntryList(_, _)
ReadSummaryMdEntryList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSummaryMdEntry(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSummaryMdEntryList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Summary Md Entry of each kind, for the lists that carry them *)
OneSummaryMdEntry == { ZeroSummaryMdEntry }

(***************************************************************************)
(* Summary Message                                                         *)
(***************************************************************************)

SummaryMessage ==
    [ classKey       : Sample(4),
      securityId     : Sample(4),
      priceType      : Sample(1),
      tradeVolume    : Sample(4),
      openInterest   : Sample(4),
      netChgPrevDay  : NetChgPrevDay,
      underlyingPx   : UnderlyingPx,
      summaryMdEntry : SampleLists(OneSummaryMdEntry) ]

EncodeSummaryMessage(message) ==
    message.classKey
        \o message.securityId
        \o message.priceType
        \o message.tradeVolume
        \o message.openInterest
        \o EncodeNetChgPrevDay(message.netChgPrevDay)
        \o EncodeUnderlyingPx(message.underlyingPx)
        \o EncodeUIntBE(Len(message.summaryMdEntry), 1)
        \o EncodeSummaryMdEntryList(message.summaryMdEntry)

DecodeSummaryMessage(bytes) ==
    LET classKey == ReadBytes(bytes, 4) IN IF ~classKey.ok THEN Fail ELSE
    LET securityId == ReadBytes(classKey.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET priceType == ReadBytes(securityId.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET tradeVolume == ReadBytes(priceType.rest, 4) IN IF ~tradeVolume.ok THEN Fail ELSE
    LET openInterest == ReadBytes(tradeVolume.rest, 4) IN IF ~openInterest.ok THEN Fail ELSE
    LET netChgPrevDay == DecodeNetChgPrevDay(openInterest.rest) IN IF ~netChgPrevDay.ok THEN Fail ELSE
    LET underlyingPx == DecodeUnderlyingPx(netChgPrevDay.rest) IN IF ~underlyingPx.ok THEN Fail ELSE
    LET noEntries == ReadUIntBE(underlyingPx.rest, 1) IN IF ~noEntries.ok THEN Fail ELSE
    LET summaryMdEntry == ReadSummaryMdEntryList(noEntries.rest, noEntries.value) IN IF ~summaryMdEntry.ok THEN Fail ELSE
    Ok([ classKey       |-> classKey.value,
         securityId     |-> securityId.value,
         priceType      |-> priceType.value,
         tradeVolume    |-> tradeVolume.value,
         openInterest   |-> openInterest.value,
         netChgPrevDay  |-> netChgPrevDay.value,
         underlyingPx   |-> underlyingPx.value,
         summaryMdEntry |-> summaryMdEntry.value ], summaryMdEntry.rest)

ZeroSummaryMessage ==
    [ classKey       |-> [i \in 1 .. 4 |-> 0],
      securityId     |-> [i \in 1 .. 4 |-> 0],
      priceType      |-> [i \in 1 .. 1 |-> 0],
      tradeVolume    |-> [i \in 1 .. 4 |-> 0],
      openInterest   |-> [i \in 1 .. 4 |-> 0],
      netChgPrevDay  |-> ZeroNetChgPrevDay,
      underlyingPx   |-> ZeroUnderlyingPx,
      summaryMdEntry |-> << >> ]

(* Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedSummaryMessage ==
    { ZeroSummaryMessage }
        \cup { [ZeroSummaryMessage EXCEPT !.classKey = one] : one \in Sample(4) }
        \cup { [ZeroSummaryMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSummaryMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSummaryMessage EXCEPT !.tradeVolume = one] : one \in Sample(4) }
        \cup { [ZeroSummaryMessage EXCEPT !.openInterest = one] : one \in Sample(4) }
        \cup { [ZeroSummaryMessage EXCEPT !.netChgPrevDay = one] : one \in CheckedNetChgPrevDay }
        \cup { [ZeroSummaryMessage EXCEPT !.underlyingPx = one] : one \in CheckedUnderlyingPx }
        \cup { [ZeroSummaryMessage EXCEPT !.summaryMdEntry = one] : one \in SampleLists(OneSummaryMdEntry) }

(***************************************************************************)
(* Market Data Control Message: 1 bytes                                    *)
(***************************************************************************)

MarketDataControlMessage ==
    [ mdControlType : Sample(1) ]

EncodeMarketDataControlMessage(message) ==
    message.mdControlType

DecodeMarketDataControlMessage(bytes) ==
    LET mdControlType == ReadBytes(bytes, 1) IN IF ~mdControlType.ok THEN Fail ELSE
    Ok([ mdControlType |-> mdControlType.value ], mdControlType.rest)

ZeroMarketDataControlMessage ==
    [ mdControlType |-> [i \in 1 .. 1 |-> 0] ]

(* Market Data Control Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataControlMessage ==
    { ZeroMarketDataControlMessage }
        \cup { [ZeroMarketDataControlMessage EXCEPT !.mdControlType = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

SecurityDefinitionMessageCode == 13  \* 0x0d
CurrentMarketRefreshMessageCode == 11  \* 0x0b
MarketDataRefreshMessageCode == 20  \* 0x14
CurrentMarketUpdateMessageCode == 12  \* 0x0c
RecapUpdateMessageCode == 21  \* 0x15
TickerMessageCode == 14  \* 0x0e
ExpectedOpeningPriceAndSizeMessageCode == 15  \* 0x0f
IndexValueMessageCode == 22  \* 0x16
SettlementValueMessageCode == 23  \* 0x17
SummaryMessageCode == 24  \* 0x18
MarketDataControlMessageCode == 25  \* 0x19
HeartbeatMessageCode == 16  \* 0x10

Payload ==
    [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {CurrentMarketRefreshMessageCode}, body : CurrentMarketRefreshMessage ]
        \cup [ tag : {MarketDataRefreshMessageCode}, body : MarketDataRefreshMessage ]
        \cup [ tag : {CurrentMarketUpdateMessageCode}, body : CurrentMarketUpdateMessage ]
        \cup [ tag : {RecapUpdateMessageCode}, body : RecapUpdateMessage ]
        \cup [ tag : {TickerMessageCode}, body : TickerMessage ]
        \cup [ tag : {ExpectedOpeningPriceAndSizeMessageCode}, body : ExpectedOpeningPriceAndSizeMessage ]
        \cup [ tag : {IndexValueMessageCode}, body : IndexValueMessage ]
        \cup [ tag : {SettlementValueMessageCode}, body : SettlementValueMessage ]
        \cup [ tag : {SummaryMessageCode}, body : SummaryMessage ]
        \cup [ tag : {MarketDataControlMessageCode}, body : MarketDataControlMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = CurrentMarketRefreshMessageCode -> EncodeCurrentMarketRefreshMessage(message.body)
      [] message.tag = MarketDataRefreshMessageCode -> EncodeMarketDataRefreshMessage(message.body)
      [] message.tag = CurrentMarketUpdateMessageCode -> EncodeCurrentMarketUpdateMessage(message.body)
      [] message.tag = RecapUpdateMessageCode -> EncodeRecapUpdateMessage(message.body)
      [] message.tag = TickerMessageCode -> EncodeTickerMessage(message.body)
      [] message.tag = ExpectedOpeningPriceAndSizeMessageCode -> EncodeExpectedOpeningPriceAndSizeMessage(message.body)
      [] message.tag = IndexValueMessageCode -> EncodeIndexValueMessage(message.body)
      [] message.tag = SettlementValueMessageCode -> EncodeSettlementValueMessage(message.body)
      [] message.tag = SummaryMessageCode -> EncodeSummaryMessage(message.body)
      [] message.tag = MarketDataControlMessageCode -> EncodeMarketDataControlMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = CurrentMarketRefreshMessageCode -> DecodeCurrentMarketRefreshMessage(bytes)
              [] tag = MarketDataRefreshMessageCode -> DecodeMarketDataRefreshMessage(bytes)
              [] tag = CurrentMarketUpdateMessageCode -> DecodeCurrentMarketUpdateMessage(bytes)
              [] tag = RecapUpdateMessageCode -> DecodeRecapUpdateMessage(bytes)
              [] tag = TickerMessageCode -> DecodeTickerMessage(bytes)
              [] tag = ExpectedOpeningPriceAndSizeMessageCode -> DecodeExpectedOpeningPriceAndSizeMessage(bytes)
              [] tag = IndexValueMessageCode -> DecodeIndexValueMessage(bytes)
              [] tag = SettlementValueMessageCode -> DecodeSettlementValueMessage(bytes)
              [] tag = SummaryMessageCode -> DecodeSummaryMessage(bytes)
              [] tag = MarketDataControlMessageCode -> DecodeMarketDataControlMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> CurrentMarketRefreshMessageCode, body |-> one] : one \in CheckedCurrentMarketRefreshMessage }
        \cup { [tag |-> MarketDataRefreshMessageCode, body |-> one] : one \in CheckedMarketDataRefreshMessage }
        \cup { [tag |-> CurrentMarketUpdateMessageCode, body |-> one] : one \in CheckedCurrentMarketUpdateMessage }
        \cup { [tag |-> RecapUpdateMessageCode, body |-> one] : one \in CheckedRecapUpdateMessage }
        \cup { [tag |-> TickerMessageCode, body |-> one] : one \in CheckedTickerMessage }
        \cup { [tag |-> ExpectedOpeningPriceAndSizeMessageCode, body |-> one] : one \in CheckedExpectedOpeningPriceAndSizeMessage }
        \cup { [tag |-> IndexValueMessageCode, body |-> one] : one \in CheckedIndexValueMessage }
        \cup { [tag |-> SettlementValueMessageCode, body |-> one] : one \in CheckedSettlementValueMessage }
        \cup { [tag |-> SummaryMessageCode, body |-> one] : one \in CheckedSummaryMessage }
        \cup { [tag |-> MarketDataControlMessageCode, body |-> one] : one \in CheckedMarketDataControlMessage }
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
      [ZeroMessage EXCEPT !.payload = [tag |-> CurrentMarketRefreshMessageCode, body |-> ZeroCurrentMarketRefreshMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDataRefreshMessageCode, body |-> ZeroMarketDataRefreshMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CurrentMarketUpdateMessageCode, body |-> ZeroCurrentMarketUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RecapUpdateMessageCode, body |-> ZeroRecapUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickerMessageCode, body |-> ZeroTickerMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExpectedOpeningPriceAndSizeMessageCode, body |-> ZeroExpectedOpeningPriceAndSizeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexValueMessageCode, body |-> ZeroIndexValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SettlementValueMessageCode, body |-> ZeroSettlementValueMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SummaryMessageCode, body |-> ZeroSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDataControlMessageCode, body |-> ZeroMarketDataControlMessage]],
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

(* Every Current Market Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrentMarketRefreshMessage ==
    \A message \in CheckedCurrentMarketRefreshMessage :
        LET read == DecodeCurrentMarketRefreshMessage(EncodeCurrentMarketRefreshMessage(message))
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

(* Every Market Data Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRefreshMessage ==
    \A message \in CheckedMarketDataRefreshMessage :
        LET read == DecodeMarketDataRefreshMessage(EncodeMarketDataRefreshMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx3 ==
    \A message \in CheckedMdEntryPx3 :
        LET read == DecodeMdEntryPx3(EncodeMdEntryPx3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntry3 ==
    \A message \in CheckedMdEntry3 :
        LET read == DecodeMdEntry3(EncodeMdEntry3(message))
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

(* Every Prev Close Px decodes back to what was encoded, and leaves nothing over *)
RoundTripPrevClosePx2 ==
    \A message \in CheckedPrevClosePx2 :
        LET read == DecodePrevClosePx2(EncodePrevClosePx2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx4 ==
    \A message \in CheckedMdEntryPx4 :
        LET read == DecodeMdEntryPx4(EncodeMdEntryPx4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Recap Update Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripRecapUpdateMdEntry ==
    \A message \in CheckedRecapUpdateMdEntry :
        LET read == DecodeRecapUpdateMdEntry(EncodeRecapUpdateMdEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Recap Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRecapUpdateMessage ==
    \A message \in CheckedRecapUpdateMessage :
        LET read == DecodeRecapUpdateMessage(EncodeRecapUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx5 ==
    \A message \in CheckedMdEntryPx5 :
        LET read == DecodeMdEntryPx5(EncodeMdEntryPx5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCondition ==
    \A message \in CheckedTradeCondition :
        LET read == DecodeTradeCondition(EncodeTradeCondition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ticker Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTickerMdEntry ==
    \A message \in CheckedTickerMdEntry :
        LET read == DecodeTickerMdEntry(EncodeTickerMdEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ticker Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickerMessage ==
    \A message \in CheckedTickerMessage :
        LET read == DecodeTickerMessage(EncodeTickerMessage(message))
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

(* Every Symbol decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbol2 ==
    \A message \in CheckedSymbol2 :
        LET read == DecodeSymbol2(EncodeSymbol2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx6 ==
    \A message \in CheckedMdEntryPx6 :
        LET read == DecodeMdEntryPx6(EncodeMdEntryPx6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueMdEntry ==
    \A message \in CheckedIndexValueMdEntry :
        LET read == DecodeIndexValueMdEntry(EncodeIndexValueMdEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexValueMessage ==
    \A message \in CheckedIndexValueMessage :
        LET read == DecodeIndexValueMessage(EncodeIndexValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx7 ==
    \A message \in CheckedMdEntryPx7 :
        LET read == DecodeMdEntryPx7(EncodeMdEntryPx7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Value Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementValueMdEntry ==
    \A message \in CheckedSettlementValueMdEntry :
        LET read == DecodeSettlementValueMdEntry(EncodeSettlementValueMdEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Settlement Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSettlementValueMessage ==
    \A message \in CheckedSettlementValueMessage :
        LET read == DecodeSettlementValueMessage(EncodeSettlementValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Chg Prev Day decodes back to what was encoded, and leaves nothing over *)
RoundTripNetChgPrevDay ==
    \A message \in CheckedNetChgPrevDay :
        LET read == DecodeNetChgPrevDay(EncodeNetChgPrevDay(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Px decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingPx ==
    \A message \in CheckedUnderlyingPx :
        LET read == DecodeUnderlyingPx(EncodeUnderlyingPx(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Md Entry Px decodes back to what was encoded, and leaves nothing over *)
RoundTripMdEntryPx8 ==
    \A message \in CheckedMdEntryPx8 :
        LET read == DecodeMdEntryPx8(EncodeMdEntryPx8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Summary Md Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripSummaryMdEntry ==
    \A message \in CheckedSummaryMdEntry :
        LET read == DecodeSummaryMdEntry(EncodeSummaryMdEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSummaryMessage ==
    \A message \in CheckedSummaryMessage :
        LET read == DecodeSummaryMessage(EncodeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataControlMessage ==
    \A message \in CheckedMarketDataControlMessage :
        LET read == DecodeMarketDataControlMessage(EncodeMarketDataControlMessage(message))
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
