// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/LongShortPairFinancialProductLibrary.sol";
import "./libraries/Lockable.sol";

/**
 * @title Floaties Long Short Pair Financial Product Library
 */
contract FloatiesLongShortPairFinancialProductLibrary is LongShortPairFinancialProductLibrary, Lockable {
    using FixedPoint for FixedPoint.Unsigned;
    using SignedSafeMath for int256;

    struct FloatiesParameters {
        uint256 priceCap;
        uint256 priceFloor;
        uint256 initialPrice;
        uint256 leverageFactor;
    }

    mapping(address => FloatiesParameters) public longShortPairParameters;

    function setLongShortPairParameters(
        address longShortPair,
        uint256 priceCap,
        uint256 priceFloor,
        uint256 initialPrice,
        uint256 leverageFactor
    ) public nonReentrant() {
        require(ExpiringContractInterface(longShortPair).expirationTimestamp() != 0, "Invalid LSP address");
        require(priceCap > priceFloor, "Invalid bounds");

        // TODO Should we cap leverageFactor for safety?
        require(leverageFactor <= 5, "Please reduce leverageFactor");

        longShortPairParameters[longShortPair] = FloatiesParameters({
            priceCap: priceCap,
            priceFloor: priceFloor,
            initialPrice: initialPrice,
            leverageFactor: leverageFactor
        });
    }

    function percentageLongCollateralAtExpiry(int256 expiryPrice)
        public
        view
        override
        nonReentrantView()
        returns (uint256)
    {
        FloatiesParameters memory params = longShortPairParameters[msg.sender];

        // 2x Leveraged Eth Token (with a price cap and price floor) =
        //      MIN(MAX((1+((eth_price/start_price)-1)*2),floor),cap)
        // Note: ETH collateral used for this synth
        //example:
        //initialPrice = $3000 (ETH/USD)
        //expiryPrice = $3300 (ETH/USD)
        //cap = 1.5 (ETH)
        //floor = 0.5 (ETH)
        //leverageFactor = 2

        // MIN(MAX((1+((3300/3000)-1)*2), 0.5), 1.5) = 1.2 ETH

        // This represents the value of the long token(leveraged Eth holder). This function's method must return a value
        // between 0 and 1 to be used as a collateralPerPair that allocates collateral between the short and long tokens.
        // We can use the value of the long token to compute the relative distribution between long and short CFD tokens
        // by simply computing longTokenRedeemed using equation above divided by the collateralPerPair of the CFD.

        uint256 positiveExpiryPrice = expiryPrice > 0 ? uint256(expiryPrice) : 0;

        FixedPoint.Unsigned memory ethReturnFactor =
            FixedPoint.div(FixedPoint.Unsigned(positiveExpiryPrice), params.initialPrice);

        // Returns can be negative so convert to int for now
        int256 intEthReturn = int256(ethReturnFactor.rawValue) - 1e18;

        // Apply x leverage
        int256 levEthReturn = intEthReturn * int256(params.leverageFactor);
        int256 levEthPrice = levEthReturn + 1e18;

        // Ensure positivity before converting back to uint
        uint256 positiveLevEthPrice = levEthPrice >= int256(params.priceFloor) ? uint256(levEthPrice) : 0;
        uint256 upperCappedLevEthPrice =
            FixedPoint.max(FixedPoint.Unsigned(positiveLevEthPrice), FixedPoint.Unsigned(params.priceFloor)).rawValue;
        return
            FixedPoint.min(FixedPoint.Unsigned(upperCappedLevEthPrice), FixedPoint.Unsigned(params.priceCap)).rawValue;
    }
}
