// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "remix_tests.sol"; // Remix test framework
import "../contracts/GParkToken.sol"; // ваш основной контракт

contract TestToken {
    GParkToken private token;

    /// @notice вызывается перед всеми тестами
    function beforeAll() public {
        // передаем любое значение в daoSafe (в тестах оно не играет роли)
        token = new GParkToken(address(0x1234567890123456789012345678901234567890));
    }

    function testName() public {
        Assert.equal(token.name(), "GParkToken", "Token name should be GParkToken");
    }

    function testSymbol() public {
        Assert.equal(token.symbol(), "GPARK", "Token symbol should be GPARK");
    }

    function testDecimals() public {
        Assert.equal(uint(token.decimals()), uint8(18), "Token decimals should be 18");
    }

    function testTotalSupply() public {
        Assert.equal(token.totalSupply(), 0, "Initial total supply should be zero");
    }
}
