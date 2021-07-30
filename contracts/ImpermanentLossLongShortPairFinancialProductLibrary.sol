// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/LongShortPairFinancialProductLibrary.sol";
import "./libraries/Lockable.sol";

/**
 * @title Impermanent Loss Long Short Pair Financial Product Library
 */
contract ImpermanentLossLongShortPairFinancialProductLibrary is LongShortPairFinancialProductLibrary, Lockable {
    using FixedPoint for FixedPoint.Unsigned;
    using SignedSafeMath for int256;

    struct ImpermanentLossParameters {
        uint256 priceCap; // TODO
        uint256 priceFloor; // TODO
        uint256 initialPrice; // Price in terms of paired asset
        uint256 endingPrice;
        uint256 leverageFactor;
    }

    mapping(address => ImpermanentLossParameters) public longShortPairParameters;

    function setLongShortPairParameters(
        address longShortPair,
        uint256 priceCap,
        uint256 priceFloor,
        uint256 initialPrice,
        uint256 endingPrice,
        uint256 leverageFactor
    ) public nonReentrant() {
        require(ExpiringContractInterface(longShortPair).expirationTimestamp() != 0, "Invalid LSP address");
        require(priceCap > priceFloor, "Invalid bounds");
        require(leverageFactor <= 5, "Please reduce leverageFactor"); // TODO Should leverage be capped?

        //twoXLevEthContractForDifferenceParameters memory params = longShortPairParameters[LongShortPair];

        longShortPairParameters[longShortPair] = ImpermanentLossParameters({
            priceCap: priceCap,
            priceFloor: priceFloor,
            initialPrice: initialPrice,
            endingPrice: endingPrice,
            leverageFactor: leverageFactor
        });
    }

    function percentageLongCollateralAtExpiry(int256 expiryPrice) public view override returns (uint256) {
        //public override taken out
        ImpermanentLossParameters memory params = longShortPairParameters[msg.sender];

        // 2x Leveraged Eth Token (with a price cap and price floor) = MIN(MAX((1+((eth_price/start_price)-1)*2),floor),cap)
        // Note: ETH collateral used for this synth
        //example:
        //priceStart = $3000 (ETH/USD)
        //expiryPrice = $3300 (ETH/USD)
        //cap = 1.5 (ETH)
        //floor = 0.5 (ETH)
        //leverageFactor = 2

        // MIN(MAX((1+((3300/3000)-1)*2), 0.5), 1.5) = 1.2 ETH

        // This represents the value of the long token(leveraged Eth holder). This function's method must return a value
        //  between 0 and 1 to be used as a collateralPerPair that allocates collateral between the short and long tokens.
        // We can use the value of the long token to compute the relative distribution between long and short CFD tokens
        // by simply computing longTokenRedeemed using equation above divided by the collateralPerPair of the CFD.

        uint256 positiveExpiryPrice = expiryPrice > 0 ? uint256(expiryPrice) : 0;
        FixedPoint.Unsigned memory ethReturnFactor =
            FixedPoint.div(FixedPoint.Unsigned(positiveExpiryPrice), params.priceStart);
        //returns can be negative so convert to int for now
        int256 intEthReturn = int256(ethReturnFactor.rawValue) - 1e18;
        //apply 2x leverage
        int256 levEthReturn = intEthReturn * int256(params.leverageFactor);
        int256 levEthPrice = levEthReturn + 1e18;
        //ensure positivity before converting back to uint
        uint256 positiveLevEthPrice = levEthPrice >= int256(params.priceFloor) ? uint256(levEthPrice) : 0;
        uint256 upperCappedLevEthPrice =
            FixedPoint.max(FixedPoint.Unsigned(positiveLevEthPrice), FixedPoint.Unsigned(params.priceFloor)).rawValue;
        return
            FixedPoint.min(FixedPoint.Unsigned(upperCappedLevEthPrice), FixedPoint.Unsigned(params.priceCap)).rawValue;
        //do one more test on this
    }
}
